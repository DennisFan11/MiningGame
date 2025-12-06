class_name ItemVoidLogic
extends IItemTransport






func has_space():
	return true

func try_add_item(_item: LineItem) -> bool:
	return true

func try_take_item() -> LineItem:
	return null
