@abstract
class_name IItemTransport
extends Node

@abstract
func has_space() -> bool

@abstract
func try_add_item(item: LineItem) -> bool

@abstract
func try_take_item() -> LineItem
