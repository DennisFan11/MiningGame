@abstract
class_name Item
extends Resource

"""
Item 的基類
拓展此類來新增ITEM

模板:
	
func create_icon()-> Texture:
	return preload("")


"""
enum ITEM {COPPER, IORN}
static var _item_map: Dictionary[ITEM, GDScript] = {
	ITEM.COPPER : load("uid://s4wwsedlaxif"),
	ITEM.IORN : load("uid://bgfjjcfyq7k0l")
}



static func get_item_name(item_ID: ITEM)-> String:
	return ITEM.find_key(item_ID)

static func create_item(item: ITEM)-> Item:
	return _item_map[item].new()

static func get_all_item()->Array[ITEM]:
	return _item_map.keys()

## 子類複寫區
func create_icon()-> Texture:
	return preload("uid://durpmb0cpvpvi")







#
