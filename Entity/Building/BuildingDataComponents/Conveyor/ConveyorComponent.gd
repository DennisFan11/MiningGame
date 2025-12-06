class_name ConveyorComponent
extends BeltComponent





# ==============================================================================
# 1. 公開 API - 查詢 (Queries)
# ==============================================================================

func get_line_items()-> Array[LineItem]:
	return %TransportLine.get_line_items()

# ==============================================================================
# 2. 物流實現
# ==============================================================================


func _process(delta: float) -> void:
	if %TransportLine.has_space():
		var item = __get_input_item()
		if item:
			item.line_provider = _line_provider[__index]
			%TransportLine.try_add_item(item)
		print("Conveyor get input item: ", item)
		


@onready var _line_provider: Array[LineProvider] = [
	%LineProvider, %LineProvider2, %LineProvider3
]

var __index: int = 0
@onready var __in_arr: Array[InputPort] = [%InputPort, %InputPort2, %InputPort3]
func __get_input_item()-> LineItem:
	for i in range(3): ## 最多嘗試三次
		__index = (__index+1) % __in_arr.size()
		var line = __in_arr[__index].from_line
		if not line:
			continue
		var item = line.try_take_item()
		if item:
			return item
	return 












#
