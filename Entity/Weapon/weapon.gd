@abstract
class_name Weapon
extends Node2D
"""
Weapon 的 抽象基類 
必須實作 _attack
"""

@export 
var ATTACK_CD = 0.3

@abstract 
func _attack()-> void



## 外部接口 (被 WeaponController 使用 )

var fire_cooldown: float = 0.0
func attack(dt: float):
	fire_cooldown += dt
	while fire_cooldown > ATTACK_CD:
		fire_cooldown -= ATTACK_CD
		_attack()
		
	
	
