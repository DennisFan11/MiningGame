extends GutTest

"""

Building系統完整性測試
目的：確保BuildingDB中定義的所有建築物配置數據(BuildingData)都是有效的，
並且在三個生命週期階段(PLAN, CONSTRUCT, COMPLETE)都能正確生成對應的實體，
且所有必要的依賴(Dependencies)都能成功注入，無遺漏。
"""

func before_all():
	# 確保 BuildingDB 已初始化
	if BuildingDB.types.is_empty():
		BuildingDB._static_init()
		
	# 註冊 Global Managers (Mock) 以滿足某些 Component 的依賴
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


# 目的：遍歷資料庫中所有類型的建築，驗證其實例化過程不會報錯，且所有組件依賴均被滿足
func test_all_building_instances_integrity():
	var checked_count = 0
	
	for type_name in BuildingDB.types:
		var type = BuildingDB.types[type_name]
		for data in type.get_buildings():
			# 測試每個階段的實體生成與依賴
			# Mock Controller 用於注入
			var mock_controller = BuildingController.new()
			mock_controller.data = data
			mock_controller.coord = Vector2i.ZERO
			autoqfree(mock_controller)
			
			# 0: PLAN, 1: CONSTRUCT, 2: COMPLETE (模擬 Entity 生成)
			# 1. 測試 PLAN 視覺實體
			# 目的：驗證 "計畫階段" 的視覺實體是否有缺漏的依賴
			var plan_entity = EntityDB.create_building_visual(0, data, mock_controller)
			_verify_entity_integrity(plan_entity, "PLAN: %s" % data.get_building_name())
			checked_count += 1
			
			# 2. 測試 CONSTRUCT 視覺實體
			# 目的：驗證 "施工階段" 的視覺實體依賴完整性
			var construct_entity = EntityDB.create_building_visual(1, data, mock_controller)
			_verify_entity_integrity(construct_entity, "CONSTRUCT: %s" % data.get_building_name())
			checked_count += 1
			
			# 3. 測試 COMPLETE (實體組件依賴)
			# 目的：驗證 "完工階段" 的實體（通常包含邏輯組件）依賴完整性
			# 這是最關鍵的步驟，因為大部分邏輯代碼 (如物流、生產) 都在此階段運作
			var complete_entity = EntityDB.create_building_visual(2, data, mock_controller)
			
			# 模擬額外依賴 (LogisticIO 需要 _logistic_manager)
			# LogisticIO 使用 `_logistic_manager` (全域) 和 `__building_controller` (本地)。
			# verify_entity_integrity 會檢查這些依賴。
			
			# 為了讓 LogisticManager 相關依賴能被解析
			# Smoke test 僅檢查變數是否被設置。
			# _on_setuped 在 create_building_visual -> final_setup 中執行。
			# 因此依賴必須準備就緒。全域 DI 已在 before_all 中處理。
			
			_verify_entity_integrity(complete_entity, "COMPLETE: %s" % data.get_building_name())
			checked_count += 1
			
	gut.p("Checked %d building instances across stages." % checked_count)
	assert_gt(checked_count, 0, "應至少迭代一些建築")

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
					
				fail_test("缺少依賴: %s.%s 為空 (%s)" % [script_name, p_name, context])
			else:
				pass_test("依賴已解析: %s.%s" % [node.name, p_name])
