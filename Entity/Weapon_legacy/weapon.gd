@abstract
class_name Weapon
extends Node2D
"""
Weapon 的 抽象基類 
必須實作 _attack
"""

@export
var ATTACK_CD = 0.3


## 單次攻擊 
@abstract
func _attack() -> void


## 外部接口 (被 WeaponController 使用 )

var fire_cd: float = 0.0
func attack(dt: float):
	fire_cd -= dt
	
	# 當冷卻時間足夠時，多次觸發攻擊
	while fire_cd <= 0.0 and Input.is_action_pressed("attack"):
		_attack()
		fire_cd += ATTACK_CD
	
	if fire_cd < 0.0:
		fire_cd = 0.0

		
## WeaponController ========================

func _process(dt: float) -> void:
	## attack input
	attack(dt)
	
	var attack_vec: Vector2 = _get_attack_vec()
	
	if is_vec_faced(attack_vec, Vector2.DOWN):
		self.z_index = 2
	else:
		self.z_index = 0
	
	global_rotation = attack_vec.angle()

	if is_vec_faced(attack_vec, Vector2.LEFT):
		self.scale.y = -1.0
	else:
		self.scale.y = 1.0


func is_vec_faced(v1: Vector2, v2: Vector2) -> bool:
	return v1.dot(v2) >= 0.0

func _get_attack_vec() -> Vector2:
	return (get_global_mouse_position() - global_position).normalized()
