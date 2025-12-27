class_name BuilderComponentData
extends ComponentData

var team: int

func _init(p_team: int = 0):
	team = p_team

func get_component() -> Component:
	var scene = preload("res://Entity/ComponentSystem/CommonComponents/Builder/BuilderComponent.tscn")
	return scene.instantiate()

func get_property() -> String:
	return "builder_component"
