class_name Building
extends BuildingI

"""
"""


func get_class_name()-> StringName:
	return "Building"



func _icon_init():
	var icon = Icon.new()
	icon.texture = data.get_icon()
	icon.set_pos(Vector2.ZERO)
	#icon.set_color(Icon.COLOR.WHITE)
	add_child(icon)
