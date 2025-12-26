class_name HealthComponentData
extends ComponentData

var max_hp: float

func _init(p_max_hp: float = 100.0):
	max_hp = p_max_hp

func get_component() -> Component:
	return HealthComponent.new()

func get_property() -> String:
	return "__health_component"
