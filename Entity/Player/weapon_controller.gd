class_name WeaponController
extends Node2D







func _attack_input(dt: float):
	if Input.is_action_pressed("attack"):
		var weapon = _get_weapon()
		
		if not weapon:
			return 
		
		weapon.attack(dt)


func _process(delta: float) -> void:
	_attack_input(delta)
	var weapon:Weapon = _get_weapon()
	if not weapon:
		return 
	
	var attack_vec: Vector2 = _get_attack_vec()
	
	if is_look_down(attack_vec):
		weapon.z_index = 2
	else:
		weapon.z_index = 0
	
	%Hand.global_rotation = attack_vec.angle()
	
	if is_look_left(attack_vec):
		weapon.scale.y = -1.0
	else:
		weapon.scale.y = 1.0
	

func is_look_down(vec: Vector2) -> bool:
	return is_vec_faced(vec, Vector2.DOWN)


func is_look_left(vec: Vector2) -> bool:
	return is_vec_faced(vec, Vector2.LEFT)

func is_vec_faced(v1: Vector2, v2: Vector2)-> bool:
	return v1.dot(v2) >= 0.0






func _get_attack_vec()-> Vector2:
	return %AimController.get_attack_vec()


func _get_weapon()-> Weapon:
	return %Gun
	for i in get_children():
		if i is Weapon:
			return i
	return null


#
