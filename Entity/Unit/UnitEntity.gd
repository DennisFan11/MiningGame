class_name UnitEntity
extends Entity

var data: UnitData:
	set(new):
		data = new
		__loca_injector.register("__unit_data", data)

var state: UnitState:
	set(new):
		state = new
		__loca_injector.register("__unit_state", state)
		state.on_change.connect(
			__loca_injector.re_inject.bindv([self, "__unit_state", state])
		)

func get_class_name() -> StringName:
	return &"UnitEntity"

func _ready() -> void:
	super ()
