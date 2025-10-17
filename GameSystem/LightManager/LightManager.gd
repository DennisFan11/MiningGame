class_name LightManager
extends Node2D



const EDGE = 100000.0



func _ready() -> void:
	DI.register("_light_manager", self)
	%LightPolygon.polygon = [
		Vector2(-EDGE, -EDGE),
		Vector2(EDGE, -EDGE),
		Vector2(EDGE, EDGE),
		Vector2(-EDGE, EDGE),
	]



## 返回
func create_light(scale_rate: float = 1.0)-> Node2D:
	var light = preload("uid://b7altess1fi1w").instantiate()
	light.scale *= scale_rate
	%CanvasGroup.add_child(light)
	return light






#
