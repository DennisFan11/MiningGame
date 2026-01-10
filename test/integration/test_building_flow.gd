extends GutTest

var _building_manager: BuildingManager
var _building_service: BuildingService
var _terrain_manager: TerrainManager
var _player_item_repo: PlayerItemRepo

# 模擬 TerrainManager 以避免地圖依賴
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
	# 添加虛擬 _building_node 以滿足 _ready 要求
	var building_node = Node2D.new()
	building_node.name = "_building_node"
	_building_manager.add_child(building_node)
	# script-instantiated 的節點，% access 可能會 fail 如果沒有 owner
	# 但只要我們修正 spawn_path 即可。
	
	add_child_autofree(_building_manager)
	
	# 修正 Spawner Path
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

# 目的：使用 Service 層級 API 測試完整的建築流程
# 流程：創建 Plan -> 升級為 Construct -> 投入資源 -> 完成建造 (Complete)
# 這驗證了 BuildingService 與 BuildingManager 之間的協作是否正確
func test_full_construction_flow():
	# 1. 生成計畫 (Plan)
	var coord = Vector2i(5, 5)
	# 使用 load 模擬真實傳遞 resource_path 的行為
	var data_script = load("res://test/integration/resources/DummyBuildingData.gd")
	var data = data_script.new()
	var state = BuildingState.new(coord, BitmaskManager.TEAM.IDLE, GridDirs.DIR.UP)
	
	# 執行: 建造計畫
	_building_service.request_build_plan(coord, data.get_script().resource_path, state.to_dict())
	
	# 驗證: Plan 已創建
	var building = _building_manager.get_block(coord)
	assert_not_null(building, "應創建建築")
	assert_true(building is BuildingController, "應為 BuildingController")
	if building is BuildingController:
		assert_eq(building.stage, BuildingController.STAGE.PLAN, "應處於 PLAN 階段")
	
	# 2. 升級至 Construct
	# 目的：模擬玩家或自動化系統請求開始施工
	_building_service.request_upgrade(coord)
	
	# 驗證: Construct 階段
	building = _building_manager.get_block(coord)
	assert_not_null(building)
	if building is BuildingController:
		assert_eq(building.stage, BuildingController.STAGE.CONSTRUCT, "應處於 CONSTRUCT 階段")
		# 初始狀態應為空
		assert_eq(building.contain_item.vtotal(), 0.0, "初始應為空")
	
	# 3. 添加資源 (建造)
	# 目的：測試資源轉移機制，確保資源能從玩家倉庫正確移入建築中
	var amount = PackedItem.create({ItemDB.ITEM.IORN: 5})
	var repo = _player_item_repo
	repo.contain = PackedItem.create({ItemDB.ITEM.IORN: 100})
	
	_building_service.try_transfer_resource(coord, amount, repo)
	
	building = _building_manager.get_block(coord)
	assert_eq(building.contain_item.item_set.get(ItemDB.ITEM.IORN, 0.0), 5.0, "資源應被添加")
	assert_eq(building.stage, BuildingController.STAGE.CONSTRUCT, "仍處於建設中")
	
	# 4. 完成建設
	# 目的：測試當所有需求資源滿足後，建築狀態是否正確變更為完成
	_building_service.try_transfer_resource(coord, amount, repo) # 添加剩餘的 5
	
	# 驗證: Complete 階段
	building = _building_manager.get_block(coord)
	if building is BuildingController:
		assert_eq(building.stage, BuildingController.STAGE.COMPLETE, "應處於 COMPLETE 階段")
