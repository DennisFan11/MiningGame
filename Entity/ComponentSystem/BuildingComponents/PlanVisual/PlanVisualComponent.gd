class_name PlanVisualComponent
extends Component

## Plan 視覺組件
## 顯示建築計劃的圖示

var __data: BuildingData # 透過 LocalInjector
var __building_controller: BuildingController # 透過 LocalInjector

func _on_setuped():
	_init_icon()

func _init_icon():
	if not __data:
		push_error("PlanVisualComponent: __data is null")
		return
		
	var icon = Sprite2D.new()
	icon.texture = __data.get_icon()
	
	# Auto-scale to 64x64
	if icon.texture:
		var tex_size = icon.texture.get_size()
		var target_size = Vector2(64, 64)
		icon.scale = target_size / tex_size
		
	# Sprite2D is centered by default, no need to offset position if texture is used directly
	# But Icon.gd forced SIZE=64. Assuming building textures are 64x64 or compatible.
	# This seems to be a ghost overlay?
	# For Plan, do we need it? 
	# Original code: icon.set_color(Icon.COLOR.WHITE)
	# If that adds an overlay, we should replicate or just set modulate.
	# Let's stick to simple Sprite2D first. If transparency is needed:
	# icon.modulate.a = 0.5 ? 
	# User didn't complain about color, just "no sprite2D".
	
	add_child(icon)
