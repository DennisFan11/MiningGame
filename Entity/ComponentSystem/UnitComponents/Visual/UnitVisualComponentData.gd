class_name UnitVisualComponentData
extends ComponentData

var texture: Texture2D
var size: Vector2

func _init(p_texture: Texture2D = null, p_size: Vector2 = Vector2.ZERO):
	texture = p_texture
	size = p_size

func get_component() -> Component:
	return UnitVisualComponent.new()

func get_property() -> String:
	return "__visual_component"
