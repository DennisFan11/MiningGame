class_name PropVisualComponentData
extends ComponentData

var icon: Texture

func _init(p_icon: Texture = null):
	icon = p_icon

func get_component() -> Component:
	return PropVisualComponent.new()

func get_property() -> String:
	return "__prop_visual_component"
