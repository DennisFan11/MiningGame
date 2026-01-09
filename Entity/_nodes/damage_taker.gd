class_name DamageTaker
extends Node2D


@export
var _hp: float = 100.0


signal on_hit(vel: Vector2)

var _debug_draw: DebugDraw
func damage(mount: float, vel: Vector2):
	_hp -= mount
	#_debug_draw.add_draw(func ():
		#_debug_draw.draw_string(
			#_debug_draw.FONT,
			#global_position,
			#str(mount),
			#0, -1, 40
		#)
	#)
	on_hit.emit(vel)

	if _hp <= 0.0:
		_die()






func _die():
	get_parent().queue_free()
#
