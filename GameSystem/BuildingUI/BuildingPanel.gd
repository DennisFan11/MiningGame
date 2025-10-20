#@tool
class_name BuildingPanel
extends Panel





@onready
var panel := %CarouselContainer

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("building_up"):
		panel.get_selected().move(1)
	if event.is_action_pressed("building_down"):
		panel.get_selected().move(-1)
	if event.is_action_pressed("building_right"):
		panel.move(1)
	if event.is_action_pressed("building_left"):
		panel.move(-1)
