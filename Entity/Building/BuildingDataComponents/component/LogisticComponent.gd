@abstract
class_name LogisticComponent
extends Component


func has_output_targeting(target_coord: Vector2i)-> IItemTransport:
	for i: OutputPort in _get_output_ports(self):
		if _global_to_coord(i.global_position) != target_coord:
			continue
		return i.get_line()
	return null

## 重新綁定
func port_rebind_ALG():
	## 單一建築會有多個 InputPort 和多個 OutputPort
	## 對所有 InputPort 尋找自身building是否在目標地塊其中之一的 OutputPort (n - 1)
	## 檢查方向有效性
	## 建立 InputPort 到 OutputPort 的連結緩存
	var self_coord := __building_state.coord
	for input_port:InputPort in _get_input_ports(self):
		var target_coord := _global_to_coord(input_port.global_position)
		var component := _logistic_manager.get_logistic(target_coord)
		if component:
			var from_line := component.has_output_targeting(self_coord)
			if from_line:
				input_port.from_line = from_line



# ==============================================================================
# 組件內部實現
# ==============================================================================

var _logistic_manager: LogisticManager
var __building_state: BuildingState:
	set(new):
		__building_state = new
		_logistic_manager.port_rebind(coord)## 組件轉向



func _on_setuped():
	# 註冊物流組件
	_logistic_manager.set_logistic(coord, self)
	# 端口重新綁定
	_logistic_manager.port_rebind(coord)
	# 組件隨移除
	tree_exiting.connect(_logistic_manager.erase_logistic.bind(coord))

## 別名
var coord:
	get: 
		return __building_state.coord


# ==============================================================================
# 內部工具
# ==============================================================================

## 遞歸獲取
func _get_ports(node:Node=self)-> Array[Port]:
	var ports: Array[Port] = []
	for p in node.get_children():
		if p is Port:
			ports.append(p)
		ports.append_array(_get_ports(p))
	return ports

## 遞歸獲取 input
func _get_input_ports(node:Node=self)-> Array[InputPort]:
	var ports: Array[InputPort] = []
	for p in node.get_children():
		if p is InputPort:
			ports.append(p)
		ports.append_array(_get_input_ports(p))
	return ports

## 遞歸獲取 output
func _get_output_ports(node:Node=self)-> Array[OutputPort]:
	var ports: Array[OutputPort] = []
	for p in node.get_children():
		if p is OutputPort:
			ports.append(p)
		ports.append_array(_get_output_ports(p))
	return ports

## 坐標計算
static func _global_to_coord(pos: Vector2)-> Vector2i:
	return BuildingManager.global_pos_to_coord(pos)
