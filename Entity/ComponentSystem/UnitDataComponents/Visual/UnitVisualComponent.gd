class_name UnitVisualComponent
extends Component

var __body_component: BodyComponent
var _texture: Texture2D

func _on_data_set(data: ComponentData):
	if data is UnitVisualComponentData:
		_texture = data.texture

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
		
	# 適當縮放 (假設 icon 較大, 稍微縮小以適配 units)
	# 這裡先不縮放，或根據需求調整。
	# sprite.scale = Vector2(0.5, 0.5)
	
	# 掛載到 Body 下
	__body_component.body.add_child(sprite)
