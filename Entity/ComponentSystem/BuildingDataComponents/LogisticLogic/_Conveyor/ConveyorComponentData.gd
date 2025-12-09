class_name ConveyorComponentData
extends ComponentData




func get_component()-> Component:
	return preload("uid://mkj5auj0anbn").instantiate()


func get_property()-> String:
	return "__conveyor_component"
