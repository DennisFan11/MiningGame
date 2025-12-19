class_name ItemVoid
extends BuildingData


const COLOR= Color.AQUAMARINE
func _get_color()-> String:
	return "[color="+COLOR.to_html()+"]"


func get_building_name()-> String:
	return _get_color() + "物品虛空"

func get_description()-> String:
	return _get_color() + "銷毀物品"

func get_icon()-> Texture:
	return preload("uid://d017txabi7p63")


func get_component_datas()-> Array[ComponentData]:
	return [
		ComponentDB.ICON,
		ComponentDB.ALL_IN_LOGISTIC_IO,
		ComponentDB.ITEM_VOID_LOGIC,
	]
