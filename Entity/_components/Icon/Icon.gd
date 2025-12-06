@tool
class_name Icon
extends TextureRect

func set_icon(texture: Texture):
	
	self.texture = texture
	set_pos(Vector2.ZERO)

func set_pos(pos: Vector2):
	size = SIZE
	position = -SIZE/2.0 + pos

const SIZE = Vector2.ONE * 64.0



func _ready() -> void:
	
	#custom_minimum_size = SIZE
	pivot_offset = SIZE/2.0
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_pos(Vector2.ZERO)

var _sub_icon: IconSub
enum COLOR { WHITE, RED}
func set_color(c: COLOR):
	const COLOR_MAP = {
		COLOR.WHITE: Color.WHITE_SMOKE,
		COLOR.RED: Color.ORANGE_RED
	}
	if _sub_icon:
		_sub_icon.queue_free()
	_sub_icon = IconSub.new()
	add_child(_sub_icon)
	
	
	_sub_icon.modulate = COLOR_MAP.get(c) * Color(1, 1, 1, 0.2)






class IconSub:
	extends ColorRect
	func _ready() -> void:
		custom_minimum_size = SIZE
		pivot_offset = SIZE/2.0
		#expand_mode = ColorRect.EXPAND_IGNORE_SIZE
		#stretch_mode = ColorRect.STRETCH_KEEP_ASPECT_CENTERED








#
