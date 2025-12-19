class_name LogisticIOComponent
extends Component



const CONVEYOR_IN : Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT]

const CONVEYOR_OUT: Array[Vector2i] = [
	Vector2i.RIGHT]

const ALL: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


var _in_coords: Array[Vector2i]
var _out_coords: Array[Vector2i]





func _on_data_set(data: ComponentData):
	data = data as LogisticIOComponentData
	_in_coords = data.input_port
	_out_coords = data.output_port

## 
func _get_input_coords()-> Array[Vector2i]:
	var res: Array[Vector2i] = []
	for i: Vector2i in _in_coords:
		res.append(
			Vector2i(Vector2(i).rotated(global_rotation)) +
			__building_state.coord
		)
	return res

func _get_output_coords()-> Array[Vector2i]:
	var res: Array[Vector2i] = []
	for i: Vector2i in _out_coords:
		res.append(
			Vector2i(Vector2(i).rotated(global_rotation)) +
			__building_state.coord
		)
	return res


## local coord: TransportLine
var _input_map: Dictionary[Vector2i, IItemTransport] = {}



func _on_setuped():
	
	#assert(__item_transport, "no item transport")
	assert(_logistic_manager, "no logistic manager")
	assert(__building_state, "no building state")
	
	# 註冊物流組件
	_logistic_manager.set_logistic(__building_state.coord, self)
	# 端口重新綁定
	_logistic_manager.port_rebind(__building_state.coord)
	# 組件隨節點移除
	tree_exiting.connect(
		_logistic_manager.erase_logistic.bind(__building_state.coord))


var __item_transport: IItemTransport
var _logistic_manager: LogisticManager
var __building_state: BuildingState:
	set(new):
		__building_state = new
		_logistic_manager.port_rebind(__building_state.coord)## 組件轉向


	
	
## FIXME
func get_line_items()-> Array[LineItem]:
	if __item_transport is TransportLine:
		return __item_transport.get_line_items()
	return []





func _clear_input():
	_input_map.clear()

## 設定其他格對準自己的 item_source
func _set_input(global_coord: Vector2i, item_source: IItemTransport):
	var key := Vector2(global_coord-__building_state.coord).rotated(
		-global_rotation
	)
	_input_map[Vector2i(key)] = item_source




# ================================================
# 1. 公開 API - 查詢 (Queries)
# ================================================

## Logistic Logic
func get_inputs()-> Dictionary[Vector2i, IItemTransport]:
	for i in _input_map.keys():
		if not is_instance_valid(_input_map[i]):
			_input_map.erase(i)
	return _input_map



# ================================================
# 1. 內部邏輯 
# ================================================




## friend function
func _has_output_targeting(target_coord: Vector2i)-> IItemTransport:
	for out_coord: Vector2i in _get_output_coords():
		if out_coord != target_coord:
			continue
		return __item_transport
	return null



## logistic manager 重新綁定
func port_rebind_ALG():
	## 單一建築會有多個 InputPort 和多個 OutputPort
	## 對所有 InputPort 尋找自身building是否在目標地塊其中之一的 OutputPort (n - 1)
	## 檢查方向有效性
	## 建立 InputPort 到 OutputPort 的連結緩存
	_clear_input()
	for in_coord: Vector2i in _get_input_coords():
		var component := _logistic_manager.get_logistic(in_coord)
		if component:
			var item_source := component._has_output_targeting(__building_state.coord)
			if item_source:
				_set_input(in_coord, item_source)
