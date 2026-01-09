extends GutTest

var _building_manager: BuildingManager
var _building_service: BuildingService
var _terrain_manager # Mock
var _player_item_repo: PlayerItemRepo
var _bitmask_manager: BitmaskManager
var _game_controller # Mock

# Mock TerrainManager
class MockTerrainManager extends TerrainManager:
	func get_terrain(_coord: Vector2i) -> TerrainManager.TERRAIN_TYPE:
		return TerrainManager.TERRAIN_TYPE.AIR

# Mock GameController
class MockGameController extends Node2D:
	pass

# Mock Body Component
class MockBodyComponent extends BodyComponent:
	func _init():
		pass

func before_each():
	# 1. Managers Setup
	_terrain_manager = MockTerrainManager.new()
	add_child_autofree(_terrain_manager)
	DI.register("_terrain_manager", _terrain_manager)
	
	_game_controller = MockGameController.new()
	_game_controller.name = "GameController"
	add_child_autofree(_game_controller)
	DI.register("_game_controller", _game_controller)
	
	# BITMASK MANAGER - Critical for IFF
	_bitmask_manager = BitmaskManager.new()
	_bitmask_manager.name = "BitmaskManager"
	add_child_autofree(_bitmask_manager)
	# Relies on _enter_tree registration
	
	_player_item_repo = PlayerItemRepo.new()
	_player_item_repo.name = "PlayerItemRepo"
	add_child_autofree(_player_item_repo)
	DI.register("_player_item_repo", _player_item_repo)
	
	_building_manager = BuildingManager.new()
	_building_manager.name = "BuildingManager"
	var building_node = Node2D.new()
	building_node.name = "_building_node"
	_building_manager.add_child(building_node)
	add_child_autofree(_building_manager)
	
	var buildings_root = Node2D.new()
	buildings_root.name = "Buildings"
	_building_manager.add_child(buildings_root)
	_building_manager._spawner.spawn_path = buildings_root.get_path()
	
	_building_service = BuildingService.new()
	_building_service.name = "BuildingService"
	add_child_autofree(_building_service)
	DI.register("_building_service", _building_service)
	DI.register("_building_manager", _building_manager)
	
	# Wait for DI injection
	await get_tree().process_frame

func after_each():
	DI._dependence.clear()

func test_player_builder_via_unitdb():
	# 1. Create a "Player-like" Entity using UnitDB logic (Real)
	# This uses UnitDB.PLAYER (PlayerData) which defines the components
	var peer_id = 1
	var player = UnitDB.create_player(peer_id)
	add_child_autofree(player)
	
	# Verify Player has components
	# Body
	var body_comp = player.get_node_or_null("__body_component")
	assert_not_null(body_comp, "Player should have BodyComponent (__body_component)")
	if body_comp:
		assert_not_null(body_comp.body, "BodyComponent should have a body node")
		body_comp.body.global_position = Vector2(100, 100)
	
	# Builder
	var builder = player.get_node_or_null("builder_component") # BuilderComponentData property name?
	# BuilderComponentData.gd: return "builder_component"
	assert_not_null(builder, "Player should have BuilderComponent")
	
	# IFF is now internal to Builder
	var builder_iff = builder.get_node_or_null("BuilderIFF")
	assert_not_null(builder_iff, "BuilderComponent should have internal IFF (BuilderIFF)")
	
	
	# 2. Spawn a Building PLan
	var coord = Vector2i(2, 2)
	var data_script = load("res://test/integration/resources/DummyBuildingData.gd")
	var state = BuildingState.new(coord, BitmaskManager.TEAM.PLAYER, GridDirs.DIR.UP)
	_building_service.request_build_plan(coord, data_script.resource_path, state.to_dict())
	
	# Verify Plan Created
	var building = _building_manager.get_block(coord)
	assert_not_null(building, "Building should be created")
	
	# Move Building to Range
	building.global_position = Vector2(120, 120)
	
	# Wait for IFF and Physics
	await wait_seconds(0.5)
	
	# 3. Assert Builder ACTUALLY builds
	# This fails if BuilderComponent (on Player) cannot see Building (via IFF)
	assert_eq(building.stage, BuildingController.STAGE.CONSTRUCT, "Player Builder should detect and upgrade Plan")
	
	# 4. Supply Resources
	_player_item_repo.contain = PackedItem.create({ItemDB.ITEM.IORN: 100})
	
	await wait_seconds(1.0)
	assert_gt(building.contain_item.vtotal(), 0.0, "Player Builder should construct building")
