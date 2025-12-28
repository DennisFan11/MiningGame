class_name VisionComponentData
extends ComponentData

func get_component() -> Component:
	return VisionComponent.new()

func get_property() -> String:
	return "__vision_component"
