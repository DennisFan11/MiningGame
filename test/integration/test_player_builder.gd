extends GutTest

var _building_manager: BuildingManager
var _building_service: BuildingService
var _terrain_manager # Mock
var _player_item_repo: PlayerItemRepo
var _bitmask_manager: BitmaskManager
var _game_controller # Mock

# 模擬 TerrainManager
class MockTerrainManager extends TerrainManager:
	func get_terrain(_coord: Vector2i) -> TerrainManager.TERRAIN_TYPE:
		return TerrainManager.TERRAIN_TYPE.AIR

# 模擬 GameController
class MockGameController extends Node2D:
	pass

# 模擬 Body Component
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
	
	# BITMASK MANAGER - 對 IFF 很重要
	_bitmask_manager = BitmaskManager.new()
	_bitmask_manager.name = "BitmaskManager"
	add_child_autofree(_bitmask_manager)
	# 依賴 _enter_tree 註冊
	
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
	
	# 等待 DI 注入
	await get_tree().process_frame

func after_each():
	DI._dependence.clear()

# 目的：整合測試 "玩家實體 (UnitDB產生)" 與 "建築系統" 的互動
# 驗證玩家身上的 BuilderComponent 是否能正確偵測到範圍內的建築並進行互動 (IFF, Range Check)
func test_player_builder_via_unitdb():
	# 1. 使用 UnitDB 邏輯創建 "類玩家" 實體 (真實)
	# 這使用了 UnitDB.PLAYER (PlayerData) 定義組件
	var peer_id = 1
	var player = UnitDB.create_player(peer_id)
	add_child_autofree(player)
	
	# 驗證玩家組件
	# Body
	var body_comp = player.get_node_or_null("__body_component")
	assert_not_null(body_comp, "玩家應有 BodyComponent (__body_component)")
	if body_comp:
		assert_not_null(body_comp.body, "BodyComponent 應有 body 節點")
		body_comp.body.global_position = Vector2(100, 100)
	
	# Builder
	var builder = player.get_node_or_null("builder_component") # BuilderComponentData property name?
	# BuilderComponentData.gd: return "builder_component"
	assert_not_null(builder, "玩家應有 BuilderComponent")
	
	# IFF 現在是在 Builder 內部
	var builder_iff = builder.get_node_or_null("BuilderIFF")
	assert_not_null(builder_iff, "BuilderComponent 應有內部 IFF (BuilderIFF)")
	
	
	# 2. 生成建築計畫
	var coord = Vector2i(2, 2)
	var data_script = load("res://test/integration/resources/DummyBuildingData.gd")
	var state = BuildingState.new(coord, BitmaskManager.TEAM.PLAYER, GridDirs.DIR.UP)
	_building_service.request_build_plan(coord, data_script.resource_path, state.to_dict())
	
	# 驗證計畫已創建
	var building = _building_manager.get_block(coord)
	assert_not_null(building, "應創建建築")
	
	# 將建築移至範圍內
	building.global_position = Vector2(120, 120)
	
	# 等待 IFF 和 Physics
	await wait_seconds(0.5)
	
	# 3. 斷言 Builder 實際上進行建造
	# 目的：驗證 BuilderComponent 的 IFF 與自動邏輯已生效，自動將 Plan 升級為 Construct
	# 如果玩家身上的 Builder 看不到建築 (IFF 錯誤)，此測試將失敗
	assert_eq(building.stage, BuildingController.STAGE.CONSTRUCT, "玩家 Builder 應偵測到並升級 Plan")
	
	# 4. 提供資源
	_player_item_repo.contain = PackedItem.create({ItemDB.ITEM.IORN: 100})
	
	await wait_seconds(1.0)
	assert_gt(building.contain_item.vtotal(), 0.0, "玩家 Builder 應建造建築")
