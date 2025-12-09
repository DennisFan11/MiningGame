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
func get_component_datas()-> Array[ComponentData]:
	return [ComponentDB.ICON]
	



func _create_basic_icon()-> Icon:
	var icon = Icon.new()
	icon.texture = get_icon()
	icon.set_pos(Vector2.ZERO)
	return icon



func get_need_item()-> PackedItem:
	return PackedItem.create({
		ItemDB.ITEM.COPPER: 1.5,
		ItemDB.ITEM.IORN: 1.5,
	
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
