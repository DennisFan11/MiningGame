extends Node2D

## 獲取玩家的攻擊向量
func get_attack_vec()-> Vector2:
	return (%Crosshair.AimGlobalPosition - global_position
		).normalized()


const MAX_LENGTH = 300.0

const DECRESS := 7.5
const ACCELATION := 30.3
const MAX_SPEED = 4000.0

## 內準心的移動速度
var velocity: Vector2 = Vector2.ZERO


## 由 %Crosshair 決定最後瞄準位置

func _process(delta: float) -> void:
	%Crosshair.IsAttack = Input.is_action_pressed("attack")
	
	match InputManager.current_device:
		InputManager.InputDevice.KEYBOARD_MOUSE:
			_keyboard_mode(delta)
		InputManager.InputDevice.JOYPAD:
			_joypad_mode(delta)



var __no_input_time: float = 0.0

func _joypad_mode(dt: float):
	
	## 搖桿的速度輸入
	var input_vec = Input.get_vector(
		"aim_left", "aim_right", "aim_up", "aim_down"
	)
	
	if input_vec.is_zero_approx():
		__no_input_time += dt
	else:
		__no_input_time = 0.0

	var move_vec = input_vec

	## 超過一段時間未瞄準則 由左移動搖桿接管
	if input_vec.is_zero_approx() and __no_input_time > 3.0:
		move_vec = Input.get_vector("left", "right", "up", "down")
		move_vec *= 1000.0

	if move_vec.is_zero_approx():
		velocity = velocity.lerp(Vector2.ZERO, DECRESS * dt)
	else:
		velocity = velocity.lerp(move_vec * MAX_SPEED, ACCELATION * dt)
	
	
	
	var last_pos = %Crosshair.AimPosition
	last_pos += velocity * dt
	%Crosshair.AimPosition = _clamp_length(last_pos, MAX_LENGTH)

func _keyboard_mode(_dt: float):
	%Crosshair.AimGlobalPosition = get_global_mouse_position()




## TOOLS


## 返回限制後的向量
func _clamp_length(vec: Vector2, max_length: float)-> Vector2:
	return vec.normalized() * clamp(vec.length(), 0.0, max_length)
