class_name IconComponent
extends Component


var __data: BuildingData

func _on_setuped():
	assert(__data, "no buildingData")
	var node = Icon.new()
	node.set_icon(__data.get_icon())
	add_child(node)
