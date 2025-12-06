class_name Building
extends BuildingEntity

"""
"""


func get_class_name()-> StringName:
	return "Building"



func _icon_init():
	pass

func get_coord()-> Vector2i:
	return state.coord
