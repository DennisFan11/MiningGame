@abstract
class_name BuildingI
extends Node2D

var data: BuildingData




enum DIR {UP, DOWN, LEFT, RIGHT}



@abstract
func get_class_name()-> StringName



var state: BuildingState
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
	var coord: Vector2i
	var team: BitmaskManager.TEAM
	var dir: BuildingI.DIR
	func _init(
		_coord: Vector2i,
		_team: BitmaskManager.TEAM,
		_dir: BuildingI.DIR,
	) -> void:
		self.coord = _coord
		self.team = _team
		self.dir = _dir
