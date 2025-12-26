class_name UnitVisualComponentData
extends ComponentData

var texture: Texture2D

func _init(p_texture: Texture2D = null):
	texture = p_texture

func get_component() -> Component:
	return UnitVisualComponent.new()

func get_property() -> String:
	return "visual_component"
