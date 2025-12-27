class_name PropEntity
extends Entity

var data: PropData:
	set(new):
		data = new
		__loca_injector.register("__prop_data", data)
		
var state: PropState:
	set(new):
		state = new
		__loca_injector.register("__prop_state", state)

func _ready() -> void:
	super ()
