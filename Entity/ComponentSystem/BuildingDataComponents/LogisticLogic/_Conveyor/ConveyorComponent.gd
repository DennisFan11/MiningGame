class_name ConveyorComponent
extends Component


var __logistic_io_component: LogisticIOComponent
var __item_transport: IItemTransport

# ==============================================================================
# 2. 物流實現
# ==============================================================================


func _process(_delta: float) -> void:
	if __item_transport.has_space():
		var item = __get_input_item()
		if item:
			__item_transport.try_add_item(item)


@onready var _line_provider: Array[LineProvider] = [
	%LineProvider, %LineProvider2, %LineProvider3
]

var __index: int = 0
func __get_input_item()-> LineItem:
	var __in_dict: Dictionary[Vector2i, IItemTransport] = \
		__logistic_io_component.get_inputs()
	
	var key_arr: Array[Vector2i] = __in_dict.keys()
	
	for i in key_arr: ## 最多嘗試 size 次
		__index = (__index+1) % key_arr.size()
		
		if not __in_dict[key_arr[__index]]:
			continue
		
		var item = __in_dict[key_arr[__index]].try_take_item()
		if not item:
			continue
		
		match key_arr[__index]:
			Vector2i.LEFT:
				item.line_provider = _line_provider[0]
			Vector2i.UP:
				item.line_provider = _line_provider[1]
			Vector2i.DOWN:
				item.line_provider = _line_provider[2]
		#print("get input item on: ", key_arr)
		return item
	return 












#
