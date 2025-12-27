@tool
class_name AttackPath
extends Path2D





func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	%Line2D.points = curve.get_baked_points()
