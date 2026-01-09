extends GutTest

## BuildingController 單元測試

const BUILDING_SCENE = preload("res://Entity/Building/BuildingController.tscn")

func _create_building() -> BuildingController:
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	return building

func test_building_stage_enum():
	assert_eq(BuildingController.STAGE.PLAN, 0)
	assert_eq(BuildingController.STAGE.CONSTRUCT, 1)
	assert_eq(BuildingController.STAGE.COMPLETE, 2)


func test_building_default_stage():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	assert_eq(building.stage, BuildingController.STAGE.PLAN)


func test_building_default_breaking():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	assert_false(building.breaking)


func test_building_coord_sets_position():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	building.coord = Vector2i(2, 3)
	# 預期位置 = coord * BLOCK_SIZE - BLOCK_SIZE / 2
	# = (2, 3) * 64 - 32 = (128, 192) - (32, 32) = (96, 160)
	var expected = Vector2(96, 160)
	assert_eq(building.position, expected)


func test_building_contain_item_default():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	assert_not_null(building.contain_item)
	assert_true(building.contain_item.is_zero())


func test_building_is_building_finish_no_data():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	# 沒有 data 時，need_item 為空，contain_item 也為空，所以視為完成
	assert_true(building.is_building_finish())


func test_building_is_remove_finish_not_breaking():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	building.breaking = false
	# 即使 contain_item 為空，breaking=false 也不算移除完成
	assert_false(building.is_remove_finish())


func test_building_is_remove_finish_breaking_empty():
	var building = BUILDING_SCENE.instantiate()
	add_child_autofree(building)
	building.breaking = true
	# breaking=true 且 contain_item 為空，視為移除完成
	assert_true(building.is_remove_finish())


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
		# Return a dummy component to verify injection in COMPLETE stage
		return [HealthComponentData.new()]


func test_visual_entity_created_on_data_set():
	var building = _create_building()
	var data = DummyBuildingData.new()
	building.data = data
	
	var visual = building.get_node_or_null("VisualEntity")
	assert_not_null(visual, "VisualEntity should be created")
	
	var plan_visual = visual.get_node_or_null("PlanVisual")
	assert_not_null(plan_visual, "PlanVisual should be created in PLAN stage")


func test_visual_entity_changes_on_stage_change():
	var building = _create_building()
	var data = DummyBuildingData.new()
	building.data = data
	
	# Initial PLAN
	assert_not_null(building.get_node("VisualEntity/PlanVisual"))
	
	# Change to CONSTRUCT
	building.stage = BuildingController.STAGE.CONSTRUCT
	var visual = building.get_node("VisualEntity")
	assert_null(visual.get_node_or_null("PlanVisual"), "PlanVisual should be removed")
	assert_not_null(visual.get_node_or_null("ConstructVisual"), "ConstructVisual should be created")

	# Change to COMPLETE
	building.stage = BuildingController.STAGE.COMPLETE
	visual = building.get_node("VisualEntity")
	assert_null(visual.get_node_or_null("ConstructVisual"))
	# assert_not_null(visual.get_node_or_null("CompleteVisual"))

	# Now using HealthComponentData
	# Note: ComponentDB likely adds node named "HealthComponent" if it adds child.
	# But ComponentDB inject_component usually looks up component from ComponentDB/Data logic.
	# Let's check if node exists. 
	# If injection works, it should be there.
	# Wait, injection != add_child? 
	# EntityDB loop: inject_component(entity, comp_data).
	# ComponentDB.inject_component: var comp = data.get_component(); entity.add_child(comp);
	# So name is likely "HealthComponent" (default node name) or set.
	var health = visual.get_node_or_null("HealthComponent")
	if not health:
        # Maybe name is different? Look for type?
		for c in visual.get_children():
			if c is HealthComponent:
				health = c
				break
	assert_not_null(health, "Should have HealthComponent in COMPLETE stage")
