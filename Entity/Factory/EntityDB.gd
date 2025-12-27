class_name EntityDB
extends Node

"""
通用實體工廠
負責根據 EntityData 實例化場景並注入組件
"""

static func create_entity(data: EntityData, state: Object = null) -> Entity:
	var scene_path = data.scene_path
	if scene_path.is_empty():
		push_warning("EntityDB: data.scene_path is empty, using default Entity.")
		scene_path = "res://Entity/Unit/UnitEntity.tscn" # Fallback
	
	var entity: Entity
	if ResourceLoader.exists(scene_path):
		var scene = load(scene_path)
		if scene:
			entity = scene.instantiate()
		else:
			push_error("EntityDB: Failed to load scene at " + scene_path)
			return null
	else:
		# Fallback for code-only entities or missing scenes
		entity = Entity.new()
		entity.name = data.entity_name
	
	# 此處假設 Entity 有一個通用的 data 屬性 setter
	# 注意：具體的 Entity 子類 (如 UnitEntity, BuildingEntity) 可能有強型別的 data 變數
	# 我們嘗試透過 set("data", ...) 或直接賦值
	if "data" in entity:
		entity.data = data
	
	# 如果有 state，也嘗試注入
	if state and "state" in entity:
		entity.state = state
		
	# 注入組件
	for comp_data in data.get_component_datas():
		ComponentDB.inject_component(entity, comp_data)
	
	# 觸發最終設定
	if entity.has_method("final_setup"):
		entity.final_setup()
		
	return entity
