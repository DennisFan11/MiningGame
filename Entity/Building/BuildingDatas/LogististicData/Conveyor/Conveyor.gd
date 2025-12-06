
class_name Conveyor
extends BuildingData



func get_building_name()-> String:
	return "Conveyor"

func get_description()-> String:
	return "這是一個傳送帶"

func get_icon()-> Texture:
	return preload("uid://b28khqolfpx4f")


func get_components()-> Array[BuildingDB.ComponentData]:
	return [BuildingDB.CONVEYOR]
