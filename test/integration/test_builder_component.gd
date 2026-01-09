extends GutTest

# 測試目標：BuilderComponent
# 測試範圍：
# 1. 自動偵測範圍內的藍圖 (Plan) 並請求升級 (Upgrade)
# 2. 自動偵測範圍內的工地 (Construct) 並請求建造 (Build/Transfer Resource)
# 3. 確保資源足夠時才建造

var _building_manager: BuildingManager
var _building_service: BuildingService
var _player_item_repo: PlayerItemRepo
var _bitmask_manager: BitmaskManager

# Mocks
var _terrain_manager
var _game_controller

class MockTerrainManager extends TerrainManager:
	func get_terrain(_coord: Vector2i) -> TerrainManager.TERRAIN_TYPE:
		return TerrainManager.TERRAIN_TYPE.AIR

class MockBodyComponent extends BodyComponent:
	func _init():
		pass
# Wrapper to act as Entity
class TestEntity extends Node2D:
	var __body_component: BodyComponent
	func get_component(name: String):
		if name == "BodyComponent": return __body_component
		return null

func before_each():
	# 1. 基礎系統 Setup
	_terrain_manager = MockTerrainManager.new()
	add_child_autofree(_terrain_manager)
	DI.register("_terrain_manager", _terrain_manager)
	
	_game_controller = Node2D.new()
	_game_controller.name = "GameController"
	add_child_autofree(_game_controller)
	DI.register("_game_controller", _game_controller)
	
	_bitmask_manager = BitmaskManager.new()
	add_child_autofree(_bitmask_manager)
	DI.register("_bitmask_manager", _bitmask_manager)
	
	_player_item_repo = PlayerItemRepo.new()
	add_child_autofree(_player_item_repo)
	DI.register("_player_item_repo", _player_item_repo)
	
	# 2. Building System Setup
	_building_manager = BuildingManager.new()
	DI.register("_building_manager", _building_manager)
	add_child_autofree(_building_manager) # Triggers _ready, populating _spawner
	
	# Add dummy _building_node (required by BuildingManager?)
	var building_node = Node2D.new()
	building_node.name = "_building_node"
	_building_manager.add_child(building_node)
	
	# Fix Spawner
	var buildings_root = Node2D.new()
	buildings_root.name = "Buildings"
	_building_manager.add_child(buildings_root)
	# Now they are in tree, paths are valid
	_building_manager._spawner.spawn_path = buildings_root.get_path()
	
	_building_service = BuildingService.new()
	DI.register("_building_service", _building_service)
	add_child_autofree(_building_service)
	
	await get_tree().process_frame

func after_each():
	DI._dependence.clear()

func test_builder_lifecycle():
	# [Setup] 建立 Builder Entity
	var entity = TestEntity.new()
	entity.name = "BuilderEntity"
	add_child_autofree(entity)
	
	# Body (位置 100, 100)
	var body_comp = MockBodyComponent.new()
	var body_node = CharacterBody2D.new()
	body_comp.body = body_node
	body_comp.add_child(body_node)
	entity.add_child(body_comp)
	entity.__body_component = body_comp
	body_node.global_position = Vector2(100, 100)
	
	# Builder Component (測試對象)
	# Use scene to ensure % access nodes (BuildingEffect, etc.) are present
	var builder_scene = load("res://Entity/ComponentSystem/CommonComponents/Builder/BuilderComponent.tscn")
	var builder = builder_scene.instantiate()
	builder.name = "BuilderComponent"
	# 模擬 LocalInjector 注入
	builder.__body_component = body_comp
	builder.team = BitmaskManager.TEAM.PLAYER
	entity.add_child(builder)
	
	# [Action 1] 放置藍圖 (Plan) 在建造範圍內
	var coord = Vector2i(2, 2) # (128, 128) 附近
	var data_script = load("res://test/integration/resources/DummyBuildingData.gd")
	var state = BuildingState.new(coord, BitmaskManager.TEAM.PLAYER, GridDirs.DIR.UP)
	_building_service.request_build_plan(coord, data_script.resource_path, state.to_dict())
	
	# 確認藍圖生成
	var building = _building_manager.get_block(coord)
	assert_not_null(building, "應生成藍圖")
	# 手動設定建築位置以確保在 IFF 範圍內 (Builder在 100,100, IFF半徑200)
	building.global_position = Vector2(120, 120)
	
	# 等待 IFF 偵測與 Builder 反應
	await wait_seconds(0.5)
	
	# [Assert 1] Builder 應自動升級 Plan -> Construct
	assert_eq(building.stage, BuildingController.STAGE.CONSTRUCT, "Builder 應將 Plan 升級為 Construct")
	
	# [Action 2] 提供資源給 Builder (PlayerRepo)
	_player_item_repo.contain = PackedItem.create({ItemDB.ITEM.IORN: 100})
	
	# 等待建造 Tick
	await wait_seconds(1.0)
	
	# [Assert 2] Builder 應投入資源
	assert_gt(building.contain_item.vtotal(), 0.0, "Builder 應投入資源進入建築")
	
	# [Action 3] 等待建造完成
	await wait_seconds(4.0)
	
	# [Assert 3] 建築應完成
	assert_eq(building.stage, BuildingController.STAGE.COMPLETE, "Builder 應完成建築")
