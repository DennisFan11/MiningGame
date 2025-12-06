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


func port_rebind(coord: Vector2i):
	for x in range(-1, 2):
		for y in range(-1, 2):
			var offset = Vector2i(x, y)
			_port_rebind(coord + offset)
			


var _component_map: Dictionary[Vector2i, LogisticComponent] = {}
func get_logistic(coord: Vector2i)-> LogisticComponent:
	return _component_map.get(coord, null)

func set_logistic(coord: Vector2i, com: LogisticComponent):
	_component_map.set(coord, com)

func erase_logistic(coord: Vector2i):
	_component_map.erase(coord)

# ==============================================================================
# 3. 內部邏輯
# ==============================================================================
func _port_rebind(coord: Vector2i):
	var comp: LogisticComponent = get_logistic(coord)
	if not comp:
		return 
	comp.port_rebind_ALG()


## Render item
func _process(delta: float) -> void:
	queue_redraw()



func _draw() -> void:
	# 1. 收集所有物品到一個扁平的陣列中
	var all_items: Array[LineItem] = []
	
	for comp: LogisticComponent in _component_map.values():
		# append_array 比迴圈 append 更快
		all_items.append_array(comp.get_line_items())

	# 2. 直接對「所有物品」進行座標排序 (Y 為主，X 為輔)
	# 這樣保證了 Y 座標較大 (下方) 的物品永遠會蓋住 Y 座標較小 (上方) 的物品
	all_items.sort_custom(func(a, b):
		var pos_a = a.get_position()
		var pos_b = b.get_position()
		
		# 如果 Y 座標不同，上方 (Y小) 的先畫
		if not is_equal_approx(pos_a.y, pos_b.y):
			return pos_a.y < pos_b.y
		
		# 如果 Y 座標相同，左方 (X小) 的先畫
		return pos_a.x < pos_b.x
	)

	# 3. 依序繪製
	for item in all_items:
		var pos = item.get_position()
		var texture = ItemDB.get_icon(item.type)
		var size = ItemDB.ICON_SIZE 
		
		var rect = Rect2(pos - size / 2.0, size)
		draw_texture_rect(texture, rect, false)












#
