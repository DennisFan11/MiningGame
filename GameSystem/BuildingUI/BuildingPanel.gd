#@tool
class_name BuildingPanel
extends Panel


signal select_building( building_data: BuildingData )


var panel: CarouselContainer = null




func _ready() -> void:
	
	for i in %Container.get_children():
		i.queue_free()
	panel = CarouselContainer.new()
	%Container.add_child(panel)
	
	for building_types in BuildingDB.get_types():
		var column = CloumnCarouselContainer.new()
		column.BuildingType = building_types
		column.direction = CarouselContainer.DIREACTION.VERTICAL
		panel.add_child(column)
		
		
		for data in building_types.get_buildings():
			var block = BuildingContainer.new()
			block.Building_data = data
			column.add_child(block)
	## 更新字串
	_update_type_name()
	_update_building_name()



class CloumnCarouselContainer:
	extends CarouselContainer
	var BuildingType: BuildingDB.BuildingType

class BuildingContainer:
	extends Node2D
	var Building_data: BuildingData
	func _ready() -> void:
		var text = Icon.new()
		text.set_icon(Building_data.get_icon())
		add_child(text)
		
	



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("building_up"):
		panel.get_selected().move(1)
		_update_building_name()
		
	if event.is_action_pressed("building_down"):
		panel.get_selected().move(-1)
		_update_building_name()
		
	if event.is_action_pressed("building_right"):
		panel.move(1)
		_update_type_name()
		_update_building_name()
	
	if event.is_action_pressed("building_left"):
		panel.move(-1)
		_update_type_name()
		_update_building_name()
	
	## 選中建築
	if event.is_action_pressed("enter"):
		var data: BuildingData= panel.get_selected().get_selected().Building_data
		select_building.emit(data.duplicate(true))


func _update_type_name():
	var type_name = \
		(panel.get_selected() as CloumnCarouselContainer)\
		.BuildingType.get_name()
	%ColumnText.text = type_name
	
	

func _update_building_name():
	var block = panel.get_selected().get_selected()
	if block is not BuildingContainer:
		%BuildingName.text = "[color=red]Building not exist"
		%BuildingInfo.text = "[color=red]Building not exist"
		return
	%BuildingName.text = block.Building_data.get_building_name()
	%BuildingInfo.text = block.Building_data.get_description()
