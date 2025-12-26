class_name UnitMoveComponentData
extends ComponentData

func get_component() -> Component:
	return UnitMoveComponent.new()

func get_property() -> String:
	return "__unit_move_component"
