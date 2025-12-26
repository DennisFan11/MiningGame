class_name PlayerControllerComponentData
extends ComponentData

func get_component() -> Component:
	return PlayerControllerComponent.new()

func get_property() -> String:
	return "__player_controller_component"
