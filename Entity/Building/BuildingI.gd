@abstract
class_name BuildingI
extends Node2D

var _data: BuildingData

func set_data(data: BuildingData):
	_data = data
	on_data_seted()

func get_data()-> BuildingData: 
	return _data

func on_data_seted():
	_icon_init()






@abstract
func get_class_name()-> StringName

## 狀態
var coord: Vector2i
var team: BitmaskManager.TEAM
var breaking: bool



## 獲取該建築的全域 rect
func get_global_rect()-> Rect2:
	var block_size = BuildingManager.BLOCK_SIZE
	var pos = BuildingManager.coord_to_global(coord)
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



func _ready() -> void:
	position = BuildingManager.coord_to_global(coord)
	%IFF.team = team
	name = get_class_name() + " : " + str(hash(randi()))
	
	var test_text = TestText.new()
	test_text.set_label(str(name) + \
		"\ncoord: "+ str(coord))
	test_text.scale = Vector2.ONE 
	add_child(test_text)

func _icon_init():
	var icon = Icon.new()
	icon.texture = _data.get_icon()
	icon.set_pos(Vector2.ZERO)
	icon.set_color(Icon.COLOR.WHITE)
	add_child(icon)
