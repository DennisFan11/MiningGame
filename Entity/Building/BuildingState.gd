class_name BuildingState
extends Resource

signal on_change
var coord: Vector2i:
		set(new):
			coord = new
			on_change.emit()
var team: BitmaskManager.TEAM:
		set(new):
			team = new
			on_change.emit()
var dir: GridDirs.DIR:
		set(new):
			dir = new
			on_change.emit()
var breaking: bool = false:
		set(new):
			breaking = new
			on_change.emit()
func _init(
	_coord: Vector2i,
	_team: BitmaskManager.TEAM,
	_dir: GridDirs.DIR
) -> void:
	self.coord = _coord
	self.team = _team
	self.dir = _dir

func copy_state() -> BuildingState:
	var s = BuildingState.new(
		self.coord,
		self.team,
		self.dir,
	)
	s.breaking = self.breaking
	return s

func to_dict() -> Dictionary:
	return {
		"coord": coord,
		"team": team,
		"dir": dir,
		"breaking": breaking
	}

static func from_dict(data: Dictionary) -> BuildingState:
	var s = BuildingState.new(
		data.get("coord", Vector2i.ZERO),
		data.get("team", BitmaskManager.TEAM.IDLE),
		data.get("dir", GridDirs.DIR.UP)
	)
	s.breaking = data.get("breaking", false)
	return s
