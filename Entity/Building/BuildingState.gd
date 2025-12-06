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

func copy_state()-> BuildingState:
	return BuildingState.new(
		self.coord,
		self.team,
		self.dir,
	)
