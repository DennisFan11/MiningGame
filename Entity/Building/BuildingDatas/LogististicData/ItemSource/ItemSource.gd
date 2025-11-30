class_name ItemSource
extends BuildingData




func get_building_name()-> String:
	return "[color=purple]物品源"

func get_description()-> String:
	return "[color=purple]產生無限的物品"

func get_icon()-> Texture:
	return preload("uid://durpmb0cpvpvi")



func get_outputs()-> Array[Vector2i]:
	return [
		Vector2i.UP, Vector2i.DOWN, 
		Vector2i.RIGHT, Vector2i.LEFT
		]

func get_inputs()-> Array[Vector2i]:
	return [Vector2i.ZERO]
