class_name ItemVoidLogic
extends Component




var __logistic_io_component: LogisticIOComponent

func _process(_delta: float) -> void:
	for inventory: IItemTransport in __logistic_io_component.get_inputs().values():
		if inventory:
			var _item: LineItem = inventory.try_take_item()
