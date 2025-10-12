@abstract
class_name FSM_state
extends Node2D



var _fsm: FSM

@abstract func enter()-> void

@abstract func exit()-> void




func handle_process(dt: float)-> void:
	pass
func handle_physics_process(dt: float)-> void:
	pass
func handle_input(event: InputEvent) -> void:
	pass





#
