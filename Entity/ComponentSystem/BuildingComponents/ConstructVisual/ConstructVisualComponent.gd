class_name ConstructVisualComponent
extends Component

## Construct 視覺組件
## 顯示建造中圖示、進度 Shader 與拆除狀態顏色

var __data: BuildingData # 透過 LocalInjector
var __building_controller: BuildingController # 透過 LocalInjector

var _sprite: Sprite2D

func _on_setuped():
	_init_sprite()
	_update_visual()
	
	if __building_controller:
		if not __building_controller.is_connected("progress_changed", _on_progress_changed):
			__building_controller.connect("progress_changed", _on_progress_changed)
		if not __building_controller.is_connected("breaking_changed", _on_breaking_changed):
			__building_controller.connect("breaking_changed", _on_breaking_changed)
		
		# 初始同步
		_on_progress_changed(__building_controller.get_progress())
		_on_breaking_changed(__building_controller.breaking)

func _init_sprite():
	if not __data:
		return
	
	_sprite = Sprite2D.new()
	var tex = __data.get_icon()
	_sprite.texture = tex
	
	# Auto-scale to 64x64
	if tex:
		var tex_size = tex.get_size()
		var target_size = Vector2(64, 64)
		_sprite.scale = target_size / tex_size
	
	# Assign Shader Material
	var shader = preload("res://Entity/ComponentSystem/BuildingComponents/ConstructVisual/ConstructVisual.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	_sprite.material = mat
	
	add_child(_sprite)

func _on_progress_changed(progress: float):
	if _sprite:
		_sprite.material.set_shader_parameter(
			"edge", (1.0 - progress) * 0.7
		)

func _on_breaking_changed(breaking: bool):
	if _sprite:
		_sprite.material.set_shader_parameter(
			"color", ColorDB.get_building_color(
				true, breaking
			)
		)

func _update_visual():
	if __building_controller:
		_on_progress_changed(__building_controller.get_progress())
		_on_breaking_changed(__building_controller.breaking)
