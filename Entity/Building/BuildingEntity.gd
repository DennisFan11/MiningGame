@abstract
class_name BuildingEntity
extends Entity

var data: BuildingData:
	set(new):
		data = new
		__loca_injector.register("__building_data", data)

var state: BuildingState:
	set(new):
		state = new
		__loca_injector.register("__building_state", state)
		state.on_change.connect(
			__loca_injector.re_inject.bindv([self, "__building_state", state])
		)
		rotation = GridDirs.get_dir_angle(state.dir)

@abstract
func get_class_name()-> StringName



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
	
	#var test_text = TestText.new()
	#test_text.set_label(
		#"[color=green]" + \
		#data.get_building_name() + \
		#"\n\tcoord: "+ str(state.coord))
	#test_text.get_global_transform()
	#add_child(test_text)
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



	
	
