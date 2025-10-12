class_name Camera
extends Camera2D

func _ready() -> void:
	DI.register("_camera", self)





var _player: Player

const OFFSET_MAX: float = 170.0
const OFFSET_SCALE: float = 0.35
const SPEED = 8.0

func _process(delta: float) -> void:
	if not _player:
		return 
	
	var mouse_vec: Vector2 =  get_global_mouse_position()\
			- _player.get_player_position()
	var target_pos: Vector2 = _player.get_player_position() \
		+ (mouse_vec * OFFSET_SCALE).limit_length(OFFSET_MAX)
	
	position = lerp(position, target_pos, SPEED * delta)
	
	_process_shake(delta)









var shake_timer: float = 0.0
var shake_strength: float = 0.0
var rng := RandomNumberGenerator.new()

func shake(time: float = 1.0, strength: float = 5.0):
	shake_timer =  time
	shake_strength = strength


func _process_shake(delta: float) -> void:
	if shake_timer > 0:
		offset.x = rng.randf_range(-shake_strength, shake_strength)
		offset.y = rng.randf_range(-shake_strength, shake_strength)
		shake_timer = max(shake_timer - delta, 0)















#
