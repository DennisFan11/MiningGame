class_name ItemSourceInventoryData
extends ComponentData


func get_component()-> Component:
	return ItemSourceInventory.new()

func get_property()-> String:
	return "__item_transport"
