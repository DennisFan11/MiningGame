class_name BodyComponentData
extends ComponentData

var shape: Shape2D

func _init(p_shape: Shape2D = null):
	shape = p_shape

func get_component() -> Component:
	return BodyComponent.new()

func get_property() -> String:
	return "__body_component"
