class_name PropState
extends RefCounted

var position: Vector2 = Vector2.ZERO
var scale: Vector2 = Vector2.ONE
var force: Vector2 = Vector2.ZERO # For initial spawn impulse

func _init(p_pos: Vector2 = Vector2.ZERO, p_scale: Vector2 = Vector2.ONE, p_force: Vector2 = Vector2.ZERO):
	position = p_pos
	scale = p_scale
	force = p_force
