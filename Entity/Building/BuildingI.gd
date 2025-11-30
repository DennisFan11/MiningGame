@abstract
class_name BuildingI
extends Entity

var data: BuildingData




enum DIR {UP, DOWN, LEFT, RIGHT}



@abstract
func get_class_name()-> StringName



var state: BuildingState:
	set(new):
		state = new
		state.on_change.connect(_on_dir_change)


func _on_dir_change():
	match state.dir:
		DIR.UP:
			rotation = Vector2.UP.angle()
		DIR.DOWN:
			rotation = Vector2.DOWN.angle()
		DIR.LEFT:
			rotation = Vector2.LEFT.angle()
		DIR.RIGHT:
			rotation = Vector2.RIGHT.angle()
	on_dir_change.emit()
signal on_dir_change


var breaking: bool:
	set(new):
		breaking = new
		_on_breaking_been_set()

func _on_breaking_been_set():
	pass






func _ready() -> void:
	position = BuildingManager.coord_to_global(state.coord)
	%IFF.team = state.team
	name = get_class_name() + str(hash(randi()))
	
	var test_text = TestText.new()
	test_text.set_label(
		"[color=green]" + \
		data.get_building_name() + \
		"\n\tcoord: "+ str(state.coord))
	add_child(test_text)
	_icon_init()
	super()
	


func _icon_init():
	var icon = Icon.new()
	icon.texture = data.get_icon()
	icon.set_pos(Vector2.ZERO)
	icon.set_color(Icon.COLOR.WHITE)
	add_child(icon)








## 獲取該建築的全域 rect
func get_global_rect()-> Rect2:
	var block_size = BuildingManager.BLOCK_SIZE
	var pos = BuildingManager.coord_to_global(state.coord)
	return Rect2(
		pos - block_size/2.0,
		block_size
	)
func get_global_points() -> PackedVector2Array:
	var rect = get_global_rect()
	return PackedVector2Array([
		rect.position,                                # 左上
		rect.position + Vector2(rect.size.x, 0),      # 右上
		rect.position + rect.size,                    # 右下
		rect.position + Vector2(0, rect.size.y)       # 左下
	])


func copy_state()-> BuildingState:
	return BuildingState.new(
		state.coord,
		state.team,
		state.dir
	)

## 狀態
class BuildingState:
	extends RefCounted
	
	signal on_change
	var coord: Vector2i:
			set(new):
				coord = new
				on_change.emit()
	var team: BitmaskManager.TEAM:
			set(new):
				team = new
				on_change.emit()
	var dir: BuildingI.DIR:
			set(new):
				dir = new
				on_change.emit()
	func _init(
		_coord: Vector2i,
		_team: BitmaskManager.TEAM,
		_dir: BuildingI.DIR
	) -> void:
		self.coord = _coord
		self.team = _team
		self.dir = _dir
	
