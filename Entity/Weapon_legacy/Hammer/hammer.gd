extends Weapon


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@export_flags_2d_physics var bit: int


var _bitmask_manager: BitmaskManager
var _debug_draw: DebugDraw
var _sound_manager: SoundManager

const ATTACK_RANGE = 96.0
const ATTACK_ANGLE = deg_to_rad(360.-120.0)
const _RAY_COUNT = 8.0
const _TERRAIN_RAY_FIXED = 2.0
func _attack()-> void:
	const TEAM := BitmaskManager.TEAM.PLAYER
	_sound_manager.play_sound(
		[preload("uid://bc7behe7j88gs"), preload("uid://bt1yklbf78hsy")].pick_random(),
		global_position
	)
	
	_hammer_anime()
	
	_debug_draw.d_draw_sector(
		global_position,
		ATTACK_RANGE,
		_get_attack_vec().angle() - (ATTACK_ANGLE)/2.0,
		_get_attack_vec().angle() + (ATTACK_ANGLE)/2.0,
		Color.CRIMSON,
	)
	bit = _bitmask_manager.get_wall_layer(TEAM) | _bitmask_manager.get_enemy_layer(TEAM)
	
	const _add = ATTACK_ANGLE / _RAY_COUNT
	for _c in range(_RAY_COUNT+1):
		var angle = (-ATTACK_ANGLE/2.0) + _add*_c + _get_attack_vec().angle()
		var result_dict := Utility.raycast_once(
			self, 
			global_position, 
			global_position + Vector2.from_angle(angle) * ATTACK_RANGE,
			_bitmask_manager.get_wall_layer(TEAM) | _bitmask_manager.get_enemy_layer(TEAM)
		)
		_debug_draw.d_draw_line(
			global_position, 
			global_position + Vector2.from_angle(angle) * ATTACK_RANGE,
			Color.ORANGE_RED,
		)
		if result_dict:
			__damage(result_dict["collider"])
			var dir = (result_dict["position"]-global_position).normalized()
			var fixed_pos = result_dict["position"] + \
				dir*_TERRAIN_RAY_FIXED
			%DamageApply.damage_terrain(
				fixed_pos,
				DAMAGE,
				dir
			)
	%DamageApply.clear_hitted_buffer()
		




const DAMAGE = 30.0
func __damage(target):
	var taker: DamageTaker = \
		%DamageApply.get_damage_taker(target)
	if taker:
		taker.damage(DAMAGE, _get_attack_vec())










	
enum DIR {LEFT, RIGHT}
var _dir: DIR = DIR.LEFT
@onready var _base: Node2D = %Marker2D
func _hammer_anime():
	
	match _dir:
		DIR.LEFT:
			_hammer_target_tween(-ATTACK_ANGLE/2.0)
			_dir = DIR.RIGHT
		DIR.RIGHT:
			_hammer_target_tween(+ATTACK_ANGLE/2.0)
			_dir = DIR.LEFT


var TIME = self.ATTACK_CD * 0.7
var _last_tween: Tween
func _hammer_target_tween(target_rot: float):
	if _last_tween:
		_last_tween.kill()
	_last_tween = create_tween()
	_last_tween.tween_property(_base, "rotation", target_rot, TIME)\
	.set_trans(Tween.TRANS_BACK)\
	.set_ease(Tween.EASE_OUT)  # 後半段停下快，增加衝擊感
	
	









#
























#
