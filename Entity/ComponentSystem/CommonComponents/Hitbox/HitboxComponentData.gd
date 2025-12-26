class_name HitboxComponentData
extends ComponentData

var team: int

func _init(p_team: int = 0):
	team = p_team

func get_component() -> Component:
	return HitboxComponent.new()

func get_property() -> String:
	return "__hitbox_component"
