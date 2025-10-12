class_name CHASE
extends FSM_state


func enter()-> void:
	pass
func exit()-> void:
	pass

var _body: Enemy
var _player: Player

var _scan_timer: CooldownTimer = CooldownTimer.new()
func handle_process(dt: float)-> void:
	if _scan_timer.is_ready():
		_scan_timer.trigger(0.5)
		if not _body.can_see_player():
			_fsm.change_state(%IDLE)

func handle_physics_process(dt: float)-> void:
	_body.walk(dt, _player.get_player_position())


#
