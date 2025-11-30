@abstract
class_name BuildingData
extends Resource



## 建築名稱
@abstract
func get_building_name()-> String

@abstract
func get_icon()-> Texture


@abstract
func get_description()-> String


## 獲取具體實現的組件
func get_component()-> Node:
	return _create_basic_icon()
	



func _create_basic_icon()-> Icon:
	var icon = Icon.new()
	icon.texture = get_icon()
	icon.set_pos(Vector2.ZERO)
	return icon



func get_need_item()-> PackedItem:
	return PackedItem.create({
		Item.ITEM.COPPER: 1.5,
		Item.ITEM.IORN: 1.5,
	
	})






""" 通用模板
func get_building_name()-> String:
	return ""

func get_description()-> String:
	return ""

func get_icon()-> Texture:
	return preload("")
	
	






"""

#
