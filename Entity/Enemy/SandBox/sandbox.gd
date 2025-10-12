class_name Sandbox
extends CharacterBody2D


func _ready() -> void:
	%AnimationPlayer.play("HURT", 0.001)

const BACK_SPEED = 1.5
@export var hurt_curve: Curve
var mount: float = 0.0

func _process(delta: float) -> void:
	mount = clampf(mount-(delta*BACK_SPEED), 0.0, 1.0)
	%AnimationPlayer.seek(hurt_curve.sample_baked(mount))



func _on_damage_taker_on_hit(from: Vector2) -> void:
	mount += 0.3
	
	if from.x > global_position.x:
		# 右邊
		scale.x = 1.0
	else:
		scale.x = -1.0
