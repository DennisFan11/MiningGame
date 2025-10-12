class_name IDLE
extends FSM_state

var _debug_draw: DebugDraw
var _target_pos: Vector2 = Vector2.ZERO
var _body: Enemy




"""
閒置狀態
行為描述:
	四處閒逛 一旦目視敵人則兼換到 CHASE 模試

"""


## NOTE 主程式

func enter()-> void:
	_new_target()

func exit()-> void:
	pass


const MOVE_CD: float = 2.0
const WALK_DIST = 200.0
var _move_timer: CooldownTimer = CooldownTimer.new()
var _scan_timer: CooldownTimer = CooldownTimer.new()

func handle_process(dt: float)-> void:
	if _scan_timer.is_ready():
		_scan_timer.trigger(0.5)
		if _can_see_player():
			_fsm.change_state(%CHASE) 
	
	if _is_reached_target():
		_new_target()
	elif _move_timer.is_ready():
		## 移動超時
		_move_timer.trigger(MOVE_CD) 
		_new_target()
	

func handle_physics_process(dt: float)-> void:
	_body.walk(dt, _target_pos)








## NOTE TOOLS

## 重設 四處閒逛的新目標
func _new_target():
	#_target_pos = (Vector2.from_angle(randf_range(0.0, 2.0*PI))\
		#* WALK_DIST) + _body.global_position
	
	_target_pos = _body.find_clear_direction(randf_range(0.0, 2.0*PI))\
		.clampf(-WALK_DIST, WALK_DIST)\
		+ _body.global_position
	
	var from = _body.global_position
	var to = _target_pos
	_debug_draw.add_draw(func():
		_debug_draw.draw_line(
			from,
			to,
			Color.CYAN,
			3.0
		),
		0.3
	)

## 檢查是否到達目的地
func _is_reached_target()-> bool:
	return (_body.global_position - _target_pos).length() < 30

## 檢查是否能直接目視到玩家
func _can_see_player()-> bool:
	return _body.can_see_player()

#
