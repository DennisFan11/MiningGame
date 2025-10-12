class_name Crosshair
extends Node2D

var AimPosition: Vector2:
	set(new):
		AimPosition = new
		%AimCenter.position = new
	get:
		return %AimCenter.position

var AimGlobalPosition: Vector2:
	set(new):
		AimGlobalPosition = new
		%AimCenter.global_position = new
	get:
		return %AimCenter.global_position

var IsAttack: bool = false:
	set(new):
		if IsAttack != new:
			if new:
				_attack_in()
			else:
				_attack_out()
		IsAttack = new
	get: 
		return IsAttack







func _process(delta: float) -> void:
	%AimOut.position = lerp(
		%AimOut.position, AimPosition, 14.0*delta
	)
	%AimOut.rotation += (_attack_state+0.3)*delta*5.0

const ATTACK_CHANGE_TIME = 0.2
func _attack_in():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "_attack_state", 1.0, 
		ATTACK_CHANGE_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
func _attack_out():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "_attack_state", 0.0, 
		ATTACK_CHANGE_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


var _attack_state: float  = 0.0:
	set(new):
		_attack_state = new
		%AimOut.scale = Vector2.ONE*2.0 + Vector2.ONE*(1.0-new)








#
