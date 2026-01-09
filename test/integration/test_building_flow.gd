extends GutTest

var _building_manager: BuildingManager
var _building_service: BuildingService
var _terrain_manager: TerrainManager
var _player_item_repo: PlayerItemRepo

# Mock TerrainManager to avoid map dependency
class MockTerrainManager extends TerrainManager:
	func get_terrain(_coord: Vector2i) -> TerrainManager.TERRAIN_TYPE:
		return TerrainManager.TERRAIN_TYPE.AIR

func before_each():
	# Setup Managers
	_terrain_manager = MockTerrainManager.new()
	_terrain_manager.name = "TerrainManager"
	add_child_autofree(_terrain_manager)
	DI.register("_terrain_manager", _terrain_manager)
	
	# 2. Building Manager
	_building_manager = BuildingManager.new()
	_building_manager.name = "BuildingManager"
	# Add dummy _building_node to satisfy _ready
	var building_node = Node2D.new()
	building_node.name = "_building_node"
	_building_manager.add_child(building_node)
	# owner must be set for % access if we were loading a scene, 
	# but since we are script-instantiated, % access in _ready will try to find relative to the script's node.
	# The script does `get_node("%_building_node")`. 
	# If that fails it's fine as long as we fix spawn_path.
	
	add_child_autofree(_building_manager)
	
	# Fix Spawner Path
	var buildings_root = Node2D.new()
	buildings_root.name = "Buildings"
	_building_manager.add_child(buildings_root)
	_building_manager._spawner.spawn_path = buildings_root.get_path()
	
	_building_service = BuildingService.new()
	_building_service.name = "BuildingService"
	add_child_autofree(_building_service)
	
	_player_item_repo = PlayerItemRepo.new()
	_player_item_repo.name = "PlayerItemRepo"
	add_child_autofree(_player_item_repo)
	DI.register("_player_item_repo", _player_item_repo)

func after_each():
	DI._dependence.clear()

func test_full_construction_flow():
	# 1. Spawn Plan
	var coord = Vector2i(5, 5)
	# Use load to simulation real behavior passing resource_path
	var data_script = load("res://test/integration/resources/DummyBuildingData.gd")
	var data = data_script.new()
	var state = BuildingState.new(coord, BitmaskManager.TEAM.IDLE, GridDirs.DIR.UP)
	
	# Act: Build Plan
	_building_service.request_build_plan(coord, data.get_script().resource_path, state.to_dict())
	
	# Assert: Plan Created
	var building = _building_manager.get_block(coord)
	assert_not_null(building, "Building should be created")
	assert_true(building is BuildingController, "Should be BuildingController")
	if building is BuildingController:
		assert_eq(building.stage, BuildingController.STAGE.PLAN, "Should be in PLAN stage")
	
	# 2. Upgrade to Construct
	_building_service.request_upgrade(coord)
	
	# Assert: Construct Stage
	building = _building_manager.get_block(coord)
	assert_not_null(building)
	if building is BuildingController:
		assert_eq(building.stage, BuildingController.STAGE.CONSTRUCT, "Should be in CONSTRUCT stage")
		# Initial state should be empty
		assert_eq(building.contain_item.vtotal(), 0.0, "Should be empty initially")
	
	# 3. Add Resources (Construction)
	var amount = PackedItem.create({ItemDB.ITEM.IORN: 5})
	var repo = _player_item_repo
	repo.contain = PackedItem.create({ItemDB.ITEM.IORN: 100})
	
	_building_service.try_transfer_resource(coord, amount, repo)
	
	building = _building_manager.get_block(coord)
	assert_eq(building.contain_item.item_set.get(ItemDB.ITEM.IORN, 0.0), 5.0, "Resource should be added")
	assert_eq(building.stage, BuildingController.STAGE.CONSTRUCT, "Still constructing")
	
	# 4. Finish Construction
	_building_service.try_transfer_resource(coord, amount, repo) # Add remaining 5
	
	# Assert: Complete Stage
	building = _building_manager.get_block(coord)
	if building is BuildingController:
		assert_eq(building.stage, BuildingController.STAGE.COMPLETE, "Should be COMPLETE")
