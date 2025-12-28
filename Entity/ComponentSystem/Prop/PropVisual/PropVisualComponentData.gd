class_name PropVisualComponentData
extends ComponentData

var icon: Texture
var size_limit: Vector2

func _init(p_icon: Texture = null, p_size_limit: Vector2 = Vector2.ZERO):
	icon = p_icon
	size_limit = p_size_limit

func get_component() -> Component:
	return PropVisualComponent.new()

func get_property() -> String:
	return "__prop_visual_component"
