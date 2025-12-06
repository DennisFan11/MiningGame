class_name ItemSourceLogic
extends IItemTransport






func has_space():
	return false

func try_add_item(_item: LineItem) -> bool:
	return false

func try_take_item() -> LineItem:
	return LineItem.new(0.0, ItemDB.ITEM.IORN)
