class_name PropVisualComponent
extends Component

var _icon: Texture
var _sprite: Sprite2D # Store reference to sync
var _size_limit: Vector2
var _limit_scale_factor: float = 1.0

# Local Injection (Will be null in Held mode)
var __prop_body_component: PropBodyComponent

func _on_data_set(data: ComponentData):
	if data is PropVisualComponentData:
		_icon = data.icon
		_size_limit = data.size_limit
		
	if not _icon:
		_icon = preload("res://icon.svg")

func _on_setuped():
	if _icon:
		_sprite = Sprite2D.new()
		_sprite.texture = _icon
		_sprite.name = "Icon"
		
		if _size_limit != Vector2.ZERO:
			var texture_size = _icon.get_size()
			var s_x = INF
			var s_y = INF
			
			if _size_limit.x > 0:
				s_x = _size_limit.x / texture_size.x
			
			if _size_limit.y > 0:
				s_y = _size_limit.y / texture_size.y
			
			var final_scale = min(s_x, s_y)
			_limit_scale_factor = final_scale
			_sprite.scale = Vector2(final_scale, final_scale)
		
		assert( __prop_body_component )
		assert( __prop_body_component.body )
		if not __prop_body_component:
			printerr("__prop_body_component is null")
		if not __prop_body_component.body:
			printerr("__prop_body_component.body is null")
		
		
		__prop_body_component.body.add_child(_sprite)
		
