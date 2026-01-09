extends GutTest

"""
Building 系統完整性測試
遍歷 EntityDB/BuildingDB 中定義的所有實例，驗證依賴注入是否完整。
"""

func before_all():
	# 確保 BuildingDB 已初始化
	if BuildingDB.types.is_empty():
		BuildingDB._static_init()
		
	# 註冊 Global Managers (Mocks) 以滿足某些 Component 的依賴
	# LogisticIOComponent 需要 _logistic_manager (Type: LogisticManager)
	var mock_logistic = Node2D.new()
	mock_logistic.set_script(load("res://GameSystem/BuildingManager/LogisticManager.gd"))
	DI.register("_logistic_manager", mock_logistic)
	autoqfree(mock_logistic) # 測試結束自動清理
	
	var mock_building_mgr = Node2D.new()
	mock_building_mgr.set_script(load("res://GameSystem/BuildingManager/BuildingManager.gd"))
	DI.register("_building_manager", mock_building_mgr)
	autoqfree(mock_building_mgr)
	
	var mock_player_item_repo = Node2D.new()
	mock_player_item_repo.set_script(load("res://GameSystem/PlayerItemRepo/player_item_repo.gd"))
	DI.register("_player_item_repo", mock_player_item_repo)
	autoqfree(mock_player_item_repo)

	var mock_bitmask_mgr = Node2D.new()
	mock_bitmask_mgr.set_script(load("res://GameSystem/BitmaskManager/BitmaskManager.gd"))
	DI.register("_bitmask_manager", mock_bitmask_mgr)
	autoqfree(mock_bitmask_mgr)


func test_all_building_instances_integrity():
	var checked_count = 0
	
	for type_name in BuildingDB.types:
		var type = BuildingDB.types[type_name]
		for data in type.get_buildings():
			# 測試每個階段的實體生成與依賴
			# Mock Controller for injection
			var mock_controller = BuildingController.new()
			mock_controller.data = data
			mock_controller.coord = Vector2i.ZERO
			autoqfree(mock_controller)
			
			# 0: PLAN, 1: CONSTRUCT, 2: COMPLETE (模擬 Entity 生成)
			# 1. 測試 PLAN 視覺實體
			var plan_entity = EntityDB.create_building_visual(0, data, mock_controller)
			_verify_entity_integrity(plan_entity, "PLAN: %s" % data.get_building_name())
			checked_count += 1
			
			# 2. 測試 CONSTRUCT 視覺實體
			var construct_entity = EntityDB.create_building_visual(1, data, mock_controller)
			_verify_entity_integrity(construct_entity, "CONSTRUCT: %s" % data.get_building_name())
			checked_count += 1
			
			# 3. 測試 COMPLETE (實體組件依賴)
			# 這邊模擬 EntityDB.create_entity 的行為 (或 create_building_visual(2))
			# 我們直接使用 create_building_visual(2, data, controller) 來測試標準流程
			var complete_entity = EntityDB.create_building_visual(2, data, mock_controller)
			
			# 模擬額外依賴 (LogisticIO 需要 _logistic_manager, 雖然現在它是全域注入，但組件可能預期從 LocalInjector 獲取? No, Global is _xxx, Local is __xxx)
			# LogisticIO uses `_logistic_manager` (global) AND `__building_controller` (local).
			# But verify_entity_integrity checks dependencies.
			
			# 為了讓 LogisticManager 相關依賴能被解析 (如果這是在 _on_setuped 中使用)
			# Smoke test just checks if variables are SET.
			# _on_setuped runs inside create_building_visual -> final_setup.
			# So dependencies must be ready. Global DI is handled in before_all.
			
			_verify_entity_integrity(complete_entity, "COMPLETE: %s" % data.get_building_name())
			checked_count += 1
			
	gut.p("Checked %d building instances across stages." % checked_count)
	assert_gt(checked_count, 0, "Should iterate at least some buildings")

func _verify_entity_integrity(entity: Node, context: String):
	add_child_autofree(entity)
	
	# 等待一幀讓 LocalInjector 運作 (_ready -> _enter_tree)
	await wait_seconds(0.0)
	
	# 遍歷所有子節點 (Components)
	for child in entity.get_children():
		# 雖然不一定是 Component 類別 (可能是 Sprite 等)，但我們只關心有 __ 屬性的物件
		_check_node_dependencies(child, context)

func _check_node_dependencies(node: Object, context: String):
	var props = node.get_property_list()
	for p in props:
		var p_name: String = p.name
		# 檢查所有雙底線開頭的屬性 (依賴)
		if p_name.begins_with("__"):
			var value = node.get(p_name)
			
			# 斷言依賴不為空
			if value == null:
				# 嘗試獲取更多資訊以便 debug
				var script_name = "Unknown"
				if node.get_script():
					script_name = node.get_script().resource_path.get_file()
					
				fail_test("Missing Dependency: %s.%s is null (%s)" % [script_name, p_name, context])
			else:
				pass_test("Dependency Resolved: %s.%s" % [node.name, p_name])
