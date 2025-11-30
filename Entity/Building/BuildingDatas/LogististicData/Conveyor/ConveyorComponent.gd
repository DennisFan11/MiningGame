class_name ConveyorComponent
extends Component









# ==============================================================================
# 1. 公開 API - 查詢 (Queries)
# ==============================================================================

func has_output_targeting(target_coord: Vector2i)-> OutputPort:
	for i: OutputPort in _get_output_ports(self):
		if _global_to_coord(i.global_position) != target_coord:
			continue
		return i 
	return null

## 重新綁定
func port_rebind_ALG():
	## 單一建築會有多個 InputPort 和多個 OutputPort
	## 對所有 InputPort 尋找自身building是否在目標地塊其中之一的 OutputPort (n - 1)
	## 檢查方向有效性
	## 建立 InputPort 到 OutputPort 的連結緩存
	var self_coord := _buildingI.state.coord
	for input_port:InputPort in _get_input_ports(self):
		var target_coord := _global_to_coord(input_port.global_position)
		var component := _logistic_manager.get_logistic(target_coord)
		var output_port :=component.has_output_targeting(self_coord)
		if output_port:
			input_port.bind_output_port(output_port)
		



# ==============================================================================
# 2. 內部實現
# ==============================================================================


var _logistic_manager: LogisticManager

var _buildingI: BuildingI
var coord:
	get: 
		return _buildingI.state.coords

## 初始化
func _entity_ready(entity: Entity)-> void:
	assert(entity is not Building,
		"entity is not Building")
	_buildingI = entity as Building
	
	
	_logistic_manager.set_logistic(coord, self)
	
	_logistic_manager.update(coord)
	
	## 組件轉向
	_buildingI.on_dir_change.connect(_logistic_manager.update.bind(coord))
	
	## 組件移除
	tree_exiting.connect(_logistic_manager.erase_logistic.bind(coord))













# ==============================================================================
# 3. 內部工具
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
		ports.append_array(_get_ports(p))
	return ports

## 遞歸獲取 output
func _get_output_ports(node:Node=self)-> Array[OutputPort]:
	var ports: Array[OutputPort] = []
	for p in node.get_children():
		if p is OutputPort:
			ports.append(p)
		ports.append_array(_get_ports(p))
	return ports

## 坐標計算
static func _global_to_coord(pos: Vector2)-> Vector2i:
	return BuildingManager.global_pos_to_coord(pos)







#
