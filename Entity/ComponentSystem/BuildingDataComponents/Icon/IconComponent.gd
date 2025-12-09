class_name IconComponent
extends Component




var __building_data: BuildingData

func _on_setuped():
	assert(__building_data, "no buildingData")
	var node = Icon.new()
	node.set_icon(__building_data.get_icon())
	add_child(node)
