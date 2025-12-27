extends Weapon

#func _ready() -> void:
	#modulate = Color.TRANSPARENT



func _attack():
	#var tween := get_tree().create_tween()
	#tween.tween_property(self, "modulate", Color.WHITE, 0.01)
	#tween.tween_interval(0.3)
	#tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.01)
	%AnimationPlayer.play("Attack")
