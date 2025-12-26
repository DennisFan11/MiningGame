class_name UnitState
extends Resource

signal on_change

@export var team: int = 0:
	set(v):
		team = v
		on_change.emit()

# For sync purpose
@export var velocity: Vector2 = Vector2.ZERO:
	set(v):
		velocity = v
		on_change.emit() # Note: High frequency update might not want to emit every frame

func to_dict() -> Dictionary:
	return {
		"team": team,
		"vel": velocity
	}

static func from_dict(dict: Dictionary) -> UnitState:
	var s = UnitState.new()
	s.team = dict.get("team", 0)
	s.velocity = dict.get("vel", Vector2.ZERO)
	return s
