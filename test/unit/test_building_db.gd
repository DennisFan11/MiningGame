extends GutTest

class DummyBuildingDataDB extends BuildingData:
	func get_building_name() -> String: return "DummyDB"
	func get_description() -> String: return "DescDB"
	func get_icon(): return PlaceholderTexture2D.new()
	func get_need_item(): return PackedItem.new()
	func get_component_datas(): return []

func test_create_plan_returns_controller():
	var data = DummyBuildingDataDB.new()
	var state = BuildingState.new(Vector2i(1, 1), BitmaskManager.TEAM.IDLE, GridDirs.DIR.UP)
	
	var building = BuildingDB.create_type(BuildingDB.TYPE.PLAN, data, state)
	
	assert_not_null(building)
	assert_true(building is BuildingController, "Should be BuildingController")
	if building is BuildingController:
		assert_eq(building.stage, BuildingController.STAGE.PLAN)
		assert_eq(building.coord, Vector2i(1, 1))

func test_create_construct_returns_controller():
	var data = DummyBuildingDataDB.new()
	var state = BuildingState.new(Vector2i.ZERO, BitmaskManager.TEAM.IDLE, GridDirs.DIR.UP)
	
	var building = BuildingDB.create_type(BuildingDB.TYPE.CONSTRUCT, data, state)
	
	assert_true(building is BuildingController)
	if building is BuildingController:
		assert_eq(building.stage, BuildingController.STAGE.CONSTRUCT)

func test_create_building_returns_controller():
	var data = DummyBuildingDataDB.new()
	var state = BuildingState.new(Vector2i.ZERO, BitmaskManager.TEAM.IDLE, GridDirs.DIR.UP)
	
	var building = BuildingDB.create_type(BuildingDB.TYPE.BUILDING, data, state)
	
	assert_true(building is BuildingController)
	if building is BuildingController:
		assert_eq(building.stage, BuildingController.STAGE.COMPLETE)
