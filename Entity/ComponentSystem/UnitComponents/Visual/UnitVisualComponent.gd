class_name UnitVisualComponent
extends Component

var __body_component: BodyComponent
var _texture: Texture2D
var _size: Vector2

func _on_data_set(data: ComponentData):
	if data is UnitVisualComponentData:
		_texture = data.texture
		_size = data.size

func _on_setuped():
	# 依賴 BodyComponent
	if not __body_component or not __body_component.body:
		printerr("[UnitVisualComponent] Missing BodyComponent!")
		return
		
	# 建立 Sprite
	var sprite = Sprite2D.new()
	sprite.name = "VisualSprite"
	
	# 設定 Texture (預設 godot icon)
	if _texture:
		sprite.texture = _texture
	else:
		sprite.texture = preload("res://icon.svg")
		
	# 適當縮放
	if _size != Vector2.ZERO and sprite.texture:
		var tex_size = sprite.texture.get_size()
		# 避免除以零
		if tex_size.x != 0 and tex_size.y != 0:
			sprite.scale = _size / tex_size
	
	# 掛載到 Body 下
	__body_component.body.add_child(sprite)
