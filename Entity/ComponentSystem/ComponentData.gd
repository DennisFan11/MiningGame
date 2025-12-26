@abstract
class_name ComponentData
extends Resource


@abstract
func get_component() -> Component

@abstract
func get_property() -> String

func inject_to(entity: Entity):
	var comp := get_component()
	
	comp._on_data_set(self)
	entity.__loca_injector.register(get_property(), comp)
	if entity is Node:
		entity.add_child(comp)
