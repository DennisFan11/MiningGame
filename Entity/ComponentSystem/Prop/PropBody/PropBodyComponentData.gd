class_name PropBodyComponentData
extends ComponentData

var shape: Shape2D
var mass: float

func _init(p_shape: Shape2D = null, p_mass: float = 1.0):
	shape = p_shape
	mass = p_mass

func get_component() -> Component:
	return PropBodyComponent.new()

func get_property() -> String:
	return "__prop_body_component"
