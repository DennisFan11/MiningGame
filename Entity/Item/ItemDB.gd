class_name ItemDB
extends Node



enum ITEM {COPPER, IORN}
static var _item_map: Dictionary[ITEM, Item] = {
	ITEM.COPPER : preload("uid://s4wwsedlaxif").new(),
	ITEM.IORN : preload("uid://bgfjjcfyq7k0l").new()
}
const ICON_SIZE: Vector2 = Vector2.ONE * 35.0


static func get_item_name(id: ITEM)-> String:
	return ITEM.find_key(id)

static func create_item(id: ITEM)-> Item:
	return _item_map[id].new()

static func get_all_item()->Array[ITEM]:
	return _item_map.keys()

static func get_icon(id: ITEM)-> Texture:
	return _item_map[id].get_icon()
