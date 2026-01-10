extends GutTest

## BuildingController 單元測試

const BUILDING_SCENE = preload("res://Entity/Building/BuildingController.tscn")

func _create_building() -> BuildingController:
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	return building

# 目的：驗證 BuildingController.STAGE 枚舉值的定義是否符合預期 (PLAN=0, CONSTRUCT=1, COMPLETE=2)
func test_building_stage_enum():
	assert_eq(BuildingController.STAGE.PLAN, 0)
	assert_eq(BuildingController.STAGE.CONSTRUCT, 1)
	assert_eq(BuildingController.STAGE.COMPLETE, 2)


# 目的：驗證新實例化的 BuildingController 預設階段應為 PLAN
func test_building_default_stage():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	assert_eq(building.stage, BuildingController.STAGE.PLAN)


# 目的：驗證新實例化的 BuildingController 預設不處於正在拆除 (breaking) 狀態
func test_building_default_breaking():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	assert_false(building.breaking)


# 目的：驗證設定 coord 屬性時，是否會自動計算並更新 global_position (基於 BLOCK_SIZE=64)
func test_building_coord_sets_position():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	building.coord = Vector2i(2, 3)
	# 預期位置 = coord * BLOCK_SIZE - BLOCK_SIZE / 2
	# = (2, 3) * 64 - 32 = (128, 192) - (32, 32) = (96, 160)
	var expected = Vector2(96, 160)
	assert_eq(building.position, expected)


# 目的：驗證 contain_item 容器預設應為空但已初始化
func test_building_contain_item_default():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	assert_not_null(building.contain_item)
	assert_true(building.contain_item.is_zero())


# 目的：驗證當沒有設定建築數據 (data) 時，是否預設判定為建造完成 (防止崩潰或死鎖)
func test_building_is_building_finish_no_data():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	# 沒有 data 時，need_item 為空，contain_item 也為空，所以視為完成
	assert_true(building.is_building_finish())


# 目的：驗證當 breaking 為 false 時，即使容器為空，也不應判定為移除完成
func test_building_is_remove_finish_not_breaking():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	building.breaking = false
	# 即使 contain_item 為空，breaking=false 也不算移除完成
	assert_false(building.is_remove_finish())


# 目的：驗證當 breaking 為 true 且容器為空時，應判定為移除完成
func test_building_is_remove_finish_breaking_empty():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	building.breaking = true
	# breaking=true 且 contain_item 為空，視為移除完成
	assert_true(building.is_remove_finish())


# 目的：驗證 get_global_rect 是否能正確返回基於 coord 計算出的全域矩形範圍
func test_building_get_global_rect():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	building.coord = Vector2i(1, 1)
	var rect = building.get_global_rect()
	# coord (1,1) -> global (32, 32)
	# rect = (32-32, 32-32) to (32+32, 32+32) = (0,0) to (64, 64)
	assert_eq(rect.position, Vector2(0, 0))
	assert_eq(rect.size, Vector2(64, 64))


class DummyBuildingData extends BuildingData:
	func get_building_name() -> String: return "Dummy"
	func get_description() -> String: return "Desc"
	func get_icon(): return PlaceholderTexture2D.new()
	func get_need_item(): return PackedItem.new()
	func get_component_datas():
		# 返回一個虛擬組件以驗證 COMPLETE 階段的注入
		return [HealthComponentData.new()]


# 目的：驗證當設定 BuildingData 時，是否會自動建立 VisualEntity 及其初始子節點 (PlanVisual)
func test_visual_entity_created_on_data_set():
	var building = _create_building()
	var data = DummyBuildingData.new()
	building.data = data
	
	var visual = building.get_node_or_null("VisualEntity")
	assert_not_null(visual, "應創建 VisualEntity")
	
	var plan_visual = visual.get_node_or_null("PlanVisual")
	assert_not_null(plan_visual, "在 PLAN 階段應創建 PlanVisual")


# 目的：驗證當 Building Stage 改變時，VisualEntity 是否會正確切換對應的視覺子節點 (Plan -> Construct -> Complete)
func test_visual_entity_changes_on_stage_change():
	var building = _create_building()
	var data = DummyBuildingData.new()
	building.data = data
	
	# 初始狀態應為 PLAN
	assert_not_null(building.get_node("VisualEntity/PlanVisual"))
	
	# 切換至 CONSTRUCT 狀態
	building.stage = BuildingController.STAGE.CONSTRUCT
	var visual = building.get_node("VisualEntity")
	assert_null(visual.get_node_or_null("PlanVisual"), "PlanVisual 應被移除")
	assert_not_null(visual.get_node_or_null("ConstructVisual"), "應創建 ConstructVisual")

	# 切換至 COMPLETE 狀態
	building.stage = BuildingController.STAGE.COMPLETE
	visual = building.get_node("VisualEntity")
	assert_null(visual.get_node_or_null("ConstructVisual"))
	# assert_not_null(visual.get_node_or_null("CompleteVisual"))

	# 現在使用 HealthComponentData
	# 註：ComponentDB 可能會添加名為 "HealthComponent" 的節點。
	# ComponentDB.inject_component 邏輯：var comp = data.get_component(); entity.add_child(comp);
	# 所以名稱可能是 "HealthComponent"（默認節點名稱）或已設置。
	var health = visual.get_node_or_null("HealthComponent")
	if not health:
        # 也可能名稱不同？檢查類型？
		for c in visual.get_children():
			if c is HealthComponent:
				health = c
				break
	assert_not_null(health, "在 COMPLETE 階段應有 HealthComponent")
