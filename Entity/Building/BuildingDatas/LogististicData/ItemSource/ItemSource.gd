class_name ItemSource
extends BuildingData


const COLOR= Color.AQUAMARINE
func _get_color()-> String:
	return "[color="+COLOR.to_html()+"]"


func get_building_name()-> String:
	return _get_color() + "物品源"

func get_description()-> String:
	return _get_color() + "產生無限的物品"

func get_icon()-> Texture:
	return preload("uid://bfwy5p5cn5j7p")


func get_components()-> Array[BuildingDB.ComponentData]:
	return [BuildingDB.ITEM_SOURCE]
