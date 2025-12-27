class_name PropHolderComponentData
extends ComponentData

func get_component() -> Component:
	return PropHolderComponent.new()

func get_property() -> String:
	return "__prop_holder_component"
