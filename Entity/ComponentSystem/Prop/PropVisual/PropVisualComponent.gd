class_name PropVisualComponent
extends Component

var _icon: Texture
var _sprite: Sprite2D # Store reference to sync

# Local Injection (Will be null in Held mode)
var __prop_body_component: PropBodyComponent

func _on_data_set(data: ComponentData):
	if data is PropVisualComponentData:
		_icon = data.icon
		
	if not _icon:
		_icon = preload("res://icon.svg")

func _on_setuped():
	if _icon:
		_sprite = Sprite2D.new()
		_sprite.texture = _icon
		_sprite.name = "Icon"
		add_child(_sprite)

func _process(_delta: float) -> void:
	# World Mode Sync: If Body Component exists and has valid body, follow it.
	if __prop_body_component and is_instance_valid(__prop_body_component.body) and _sprite:
		_sprite.global_transform = __prop_body_component.body.global_transform
