extends GutTest

## BuildingDB 單元測試
## 測試 BuildingDB 工廠方法，確保能正確建立 BuildingController 並設定初始狀態

class DummyBuildingDataDB extends BuildingData:
	func get_building_name() -> String: return "DummyDB"
	func get_description() -> String: return "DescDB"
	func get_icon(): return PlaceholderTexture2D.new()
	func get_need_item(): return PackedItem.new()
	func get_component_datas(): return []

# 目的：驗證 create_type 方法請求 PLAN 類型時，回傳物件為 BuildingController 且狀態為 PLAN
func test_create_plan_returns_controller():
	var data = DummyBuildingDataDB.new()
	var state = BuildingState.new(Vector2i(1, 1), BitmaskManager.TEAM.IDLE, GridDirs.DIR.UP)
	
	# 測試建立 PLAN 類型的建築
	var building = BuildingDB.create_type(BuildingDB.TYPE.PLAN, data, state)
	
	assert_not_null(building)
	assert_true(building is BuildingController, "回傳值應為 BuildingController")
	if building is BuildingController:
		assert_eq(building.stage, BuildingController.STAGE.PLAN)
		assert_eq(building.coord, Vector2i(1, 1))

# 目的：驗證 create_type 方法請求 CONSTRUCT 類型時，回傳物件為 BuildingController 且狀態為 CONSTRUCT
func test_create_construct_returns_controller():
	var data = DummyBuildingDataDB.new()
	var state = BuildingState.new(Vector2i.ZERO, BitmaskManager.TEAM.IDLE, GridDirs.DIR.UP)
	
	# 測試建立 CONSTRUCT 類型的建築
	var building = BuildingDB.create_type(BuildingDB.TYPE.CONSTRUCT, data, state)
	
	assert_true(building is BuildingController)
	if building is BuildingController:
		assert_eq(building.stage, BuildingController.STAGE.CONSTRUCT)

# 目的：驗證 create_type 方法請求 BUILDING (COMPLETE) 類型時，回傳物件為 BuildingController 且狀態為 COMPLETE
func test_create_building_returns_controller():
	var data = DummyBuildingDataDB.new()
	var state = BuildingState.new(Vector2i.ZERO, BitmaskManager.TEAM.IDLE, GridDirs.DIR.UP)
	
	# 測試建立 BUILDING (COMPLETE) 類型的建築
	var building = BuildingDB.create_type(BuildingDB.TYPE.BUILDING, data, state)
	
	assert_true(building is BuildingController)
	if building is BuildingController:
		assert_eq(building.stage, BuildingController.STAGE.COMPLETE)
