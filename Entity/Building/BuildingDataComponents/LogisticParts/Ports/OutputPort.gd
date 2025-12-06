class_name OutputPort
extends Port


"""
輸出產物
"""

@export var item_transport: IItemTransport

func get_line()-> IItemTransport:
	return item_transport


#var _debug_draw: DebugDraw
#
#func _process(delta: float) -> void:
	#_debug_draw.d_draw_circle(global_position, 7.0, Color.ORANGE_RED, 0.01, 2.0, true)
