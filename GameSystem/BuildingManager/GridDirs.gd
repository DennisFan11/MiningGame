class_name GridDirs
extends Node


enum DIR {UP, DOWN, LEFT, RIGHT}
static func get_dir_angle(_dir: DIR) -> float:
	match _dir:
		DIR.UP:
			return Vector2.UP.angle()
		DIR.DOWN:
			return Vector2.DOWN.angle()
		DIR.LEFT:
			return Vector2.LEFT.angle()
		DIR.RIGHT:
			return Vector2.RIGHT.angle()
	return 0.0
static func get_dir_types() -> Array[DIR]:
	return [DIR.UP, DIR.RIGHT,
		DIR.DOWN, DIR.LEFT]
