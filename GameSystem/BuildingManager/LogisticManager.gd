class_name LogisticManager
extends Node2D


func _ready() -> void:
	DI.register("_logistic_manager", self)

"""
物流組件註冊器
"""


# ==============================================================================
# 1. 公開 API - 查詢 (Queries)
# ==============================================================================

# ==============================================================================
# 2. 公開 API - 註冊 (Register)
# ==============================================================================

var _building_manager: BuildingManager
func update(coord: Vector2i):
	for x in range(-1, 2):
		for y in range(-1, 2):
			var offset = Vector2i(x, y)
			_update(coord + offset)
			


var _component_map: Dictionary[Vector2i, ConveyorComponent] = {}
func get_logistic(coord: Vector2i)-> ConveyorComponent:
	return _component_map.get(coord, null)

func set_logistic(coord: Vector2i, com: ConveyorComponent):
	_component_map.set(coord, com)

func erase_logistic(coord: Vector2i):
	_component_map.erase(coord)
# ==============================================================================
# 3. 內部邏輯
# ==============================================================================
func _update(coord: Vector2i):
	var comp: ConveyorComponent = get_logistic(coord)
	if not comp:
		return 
	comp.port_rebind_ALG()


#func _rebind_AGL(coord: Vector2i):
	### 單一建築會有多個 InputPort 和多個 OutputPort
	### 對所有 InputPort 尋找自身building是否在目標地塊其中之一的 OutputPort (n - 1)
	### 檢查方向有效性
	### 建立 InputPort 到 OutputPort 的連結緩存
	#pass
	#
	#var building: BuildingI = _building_manager.get_block(coord)
	#if not building: 
		#return 
	#if not building is Building:
		#return 
	#if not (building as Building).component is ConveyorComponent:
		#return 
	#
	#var component: ConveyorComponent = (building as Building).component
	#
	
	
	

















#
