class_name Player
extends Node2D

@onready var body := %CharacterBody2D

var _debug_draw: DebugDraw
var _light_manager: LightManager



func _ready() -> void:
	DI.register("_player", self)
	%Builder.team = BitmaskManager.TEAM.PLAYER
	
	

func _on_injected(): 
	if not _light_manager:
		return
	
	var light = _light_manager.create_light(10)
	%RemoteTransform2D.remote_path = light.get_path()
	tree_exited.connect(light.queue_free)



func get_input_vec()-> Vector2:
	return Input.get_vector("left", "right", "up", "down")

func get_attack_vec()-> Vector2:
	return %AimController.get_attack_vec()

func get_player_position()-> Vector2:
	return %CharacterBody2D.global_position








const DECRESS := 20.5
const ACCELATION := 15.3
const MAX_SPEED = 370.0

enum {MOVE, DASH}
var _state: int = MOVE




func _process(delta: float) -> void:
	
	match _state:
		MOVE:
			_move(delta)
		DASH:
			_dash(delta)
	
	if Input.is_action_just_pressed("dash"):
		if __dash_timer.is_ready():
			__dir_speed = get_input_vec() * DASH_SPEED
			__dash_timer.trigger(DASH_TIME)
			_state = DASH
			%DASH_particle.emitting = true
	
	_debug_draw.d_draw_line(
		body.global_position,
		body.global_position + body.velocity,
		Color.WHITE, 3.0
	)












## NOTE STATE ZONE 

func _move(dt: float):
	var input_vec = get_input_vec()
	var curr_vel: Vector2 = body.velocity
	
	if input_vec.is_zero_approx():
		curr_vel = curr_vel.lerp(Vector2.ZERO, DECRESS * dt)
	else:
		curr_vel = curr_vel.lerp(input_vec * MAX_SPEED, ACCELATION * dt)
	
	body.velocity = curr_vel
	body.move_and_slide()


## Dash Context
const DASH_CD = 0.1 ## NOTE unuse
const DASH_TIME = 0.3
const DASH_SPEED = 2000.0
@export var _dash_curve: Curve
var __dir_speed: Vector2 = Vector2.ZERO
var __dash_timer: CooldownTimer = CooldownTimer.new()

func _dash(dt: float):
	if __dash_timer.is_ready():
		_state = MOVE
		body.velocity = Vector2.ZERO
		return 
	var vel = _dash_curve.sample_baked(__dash_timer.get_progress())
	body.velocity = vel * __dir_speed
	body.move_and_slide()





#
#
## 參數（建議先用這組試手感）
#var __drift_vec: Vector2 = Vector2.RIGHT
#const DRIFT_SPEED: float = 2000.0
#const DRIFT_STEER: float = 5.0          # 每秒最大轉向角速度
#const DRIFT_DAMP: float = 0.8           # 全域阻力（降到 0.6~1.0 之間）
#const DRIFT_SLIDE: float = 3.0          # 越小滑角越明顯（原本 32 太小看不出偏移）
#const AUTO_ALIGN: float = 0.05           # 自動回正更小，保留滑角
#
## 新增：用加速度推前進向（避免瞬間對齊）
#const ENGINE_ACCEL: float = 3000.0      # 前進加速度（越小越滑）
## 新增：側向抓地（越小越滑）
#const SIDE_FRICTION: float = 0.8        # 建議 0.8~1.6
## 新增：打方向時給一點側向推力，放大偏移感
#const SIDE_KICK: float = 1600.0          # 0~1200 視手感調
#
#
## 假設你前面的參數保持不變（DRIFT_SPEED/DRIFT_STEER/...）
## 新增兩個輸入動作： "throttle"(W) 、"turn_left"(A) 、"turn_right"(D)
#
#func _drift(dt: float) -> void:
	## ── 1) 讀取純量輸入：W 油門、A/D 轉向 ──
	#var throttle: float = Input.get_action_strength("up")    # W
	#var steer_axis: float = Input.get_action_strength("right") - Input.get_action_strength("left")  # D - A
	#var has_steer = abs(steer_axis) > 0.05
#
	## ── 2) 車頭方向更新：以方向盤式「角速度」旋轉 ──
	##     有輸入就依 steer_axis 旋轉；無輸入時做一點自動回正（朝當前速度方向）
	#if has_steer:
		#__drift_vec = __drift_vec.rotated(steer_axis * DRIFT_STEER * dt).normalized()
	#else:
		#var v = body.velocity
		#if v.length() > 1.0:
			#__drift_vec = __drift_vec.slerp(v.normalized(), AUTO_ALIGN).normalized()
#
	## ── 3) 分解速度：前進 v_f、側滑 v_s ──
	#var v = body.velocity
	#var v_f = __drift_vec * v.dot(__drift_vec)
	#var v_s = v - v_f
#
	## ── 4) 前進只用「加速度」往目標推
	##     油門控制目標速度的大小（放開 W 時不會瞬間歸零，只靠阻力慢慢收）
	#var v_f_target := __drift_vec * (DRIFT_SPEED * throttle)
	#v_f = v_f.move_toward(v_f_target, ENGINE_ACCEL * dt)
#
	## ── 5) 側滑保留＋側向推力：A/D 打方向時給一點側向 kick 放大偏移 ──
	#v_s *= max(0.0, 1.0 - SIDE_FRICTION * dt)
	#if has_steer:
		## steer_axis (>0 右轉，<0 左轉)；用車頭的法向量來添加側向動量
		#var ortho := __drift_vec.orthogonal()  # 逆時針 90°；方向用 steer_axis 決定正負
		#v_s += ortho * steer_axis * SIDE_KICK * dt
#
	## ── 6) 合成速度並施加輕阻力 ──
	#body.velocity = v_f + v_s
	#body.velocity -= body.velocity * DRIFT_DAMP * dt
#
	## ── 7) 視覺：車身角度 = 車頭與速度的混合方向（降低 DRIFT_SLIDE 會更有偏移感） ──
	#var speed = body.velocity.length()
	#if speed > 0.1:
		#var vel_dir = body.velocity / speed
		#var mix := 1.0 / max(DRIFT_SLIDE, 1.0)
		#var blend := __drift_vec.lerp(vel_dir, mix).normalized()
		#body.rotation = blend.angle()
#
	#body.move_and_slide()









#
