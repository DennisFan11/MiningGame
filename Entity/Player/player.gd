class_name Player
extends Node2D

@onready var body := %CharacterBody2D


func _ready() -> void:
	DI.register("_player", self)

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
		if not __dash_timer.is_ready():
			return
		__dir_speed = get_input_vec() * DASH_SPEED
		__dash_timer.trigger(DASH_TIME)
		_state = DASH


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
const DASH_SPEED = 1000.0
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
