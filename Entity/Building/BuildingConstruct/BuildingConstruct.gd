class_name BuildingConstruct
extends BuildingEntity


var need_item: PackedItem:
	get:
		return data.get_need_item()

var contain_item: PackedItem = PackedItem.new()

func update_progress():
	_progress = contain_item.vtotal() / need_item.vtotal()


func is_building_finish() -> bool:
	return need_item.sub(contain_item).is_zero()

func is_remove_finish() -> bool:
	return breaking and contain_item.is_zero()

func set_full_item() -> void:
	contain_item = need_item.dup_self()
	update_progress()


func get_class_name() -> StringName:
	return "BuildingConstruct"

func _on_breaking_been_set():
	_set_breaking_color(breaking)

func _icon_init():
	var icon = %Icon
	icon.texture = data.get_icon()
	icon.set_pos(Vector2.ZERO)


var _progress: float = 0.0:
	set(new):
		_progress = new
		%Icon.material.set_shader_parameter(
			"edge", (1.0 - _progress) * 0.7
		)
		
func _set_breaking_color(is_breaking: bool):
	%Icon.material.set_shader_parameter(
			"color", ColorDB.get_building_color(
				true, is_breaking
			)
		)

func _ready():
	super ()
	_setup_multiplayer_sync()

func _setup_multiplayer_sync():
	var sync = NetworkSynchronizer.new()
	sync.name = "Synchronizer"
	sync.set_multiplayer_authority(1)
	
	sync.add_property(NodePath(":breaking"))
	
	add_child(sync )
	
	if not multiplayer.is_server():
		sync.start()
