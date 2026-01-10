class_name EntityDB
extends Node

"""
通用實體工廠
負責根據 EntityData 實例化場景並注入組件
"""

static func create_entity(data: EntityData) -> Entity:
	var entity = Entity.new()
	entity.name = data.entity_name
	

	# 統一使用 __data 名稱注入到 LocalInjector
	entity.__loca_injector.register("__data", data)
	
	# 注入組件
	for comp_data in data.get_component_datas():
		ComponentDB.inject_component(entity, comp_data)
	
	# 觸發最終設定
	if entity.has_method("final_setup"):
		entity.final_setup()
		
	return entity

## Factory Method for Building Visuals
static func create_building_visual(stage: int, data: BuildingData, controller: Node = null) -> Entity:
	var entity = Entity.new()
	entity.name = "VisualEntity"
	
	# Register Dependencies for Components
	entity.__loca_injector.register("__data", data)
	if controller:
		entity.__loca_injector.register("__building_controller", controller)
	
	match stage:
		0: # BuildingController.STAGE.PLAN
			var comp = PlanVisualComponent.new()
			comp.name = "PlanVisual"
			entity.add_child(comp)
			
		1: # BuildingController.STAGE.CONSTRUCT
			var comp = ConstructVisualComponent.new()
			comp.name = "ConstructVisual"
			entity.add_child(comp)
			
		2: # BuildingController.STAGE.COMPLETE
			# Inject Components defined in Data
			for comp_data in data.get_component_datas():
				ComponentDB.inject_component(entity, comp_data)
	
	# Trigger final setup to ensure injection happens for added children
	if entity.has_method("final_setup"):
		entity.final_setup()
				
	return entity
