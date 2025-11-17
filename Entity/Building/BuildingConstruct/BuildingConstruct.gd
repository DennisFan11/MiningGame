class_name BuildingConstruct
extends BuildingI







var need_item: PackedItem:
	get:
		return get_data().get_need_item()

var contain_item: PackedItem = PackedItem.new()



func get_class_name()-> StringName:
	return "BuildingConstruct"






func _icon_init():
	var icon = %Icon
	icon.texture = _data.get_icon()
	icon.set_pos(Vector2.ZERO)
	#icon.set_color(Icon.COLOR.WHITE)
	
	#add_child(icon)



var progress: float = 0.0:
	set(new):
		progress = new
		%Icon.material.set_shader_parameter(
			"edge", (1.0-progress)*0.7
		)
		#print("edge: ", progress)
		
func set_breaking_color(breaking: bool):
	%Icon.material.set_shader_parameter(
			"color", ColorDB.get_building_color(
				true, breaking
			)
		)
