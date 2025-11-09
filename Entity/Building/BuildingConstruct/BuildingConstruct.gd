class_name BuildingConstruct
extends BuildingI







var need_item: PackedItem:
	get:
		return get_data().get_need_item()

var contain_item: PackedItem = PackedItem.new()



func get_class_name()-> StringName:
	return "BuildingConstruct"















#
