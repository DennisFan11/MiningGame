class_name LogisticManager
extends Node2D


func _ready() -> void:
	DI.register("_logistic_manager", self)

"""
物流組件註冊器
"""


# ==============================================================================
# 1. 公開 API
# ==============================================================================


func port_rebind(coord: Vector2i):
	for x in range(-1, 2):
		for y in range(-1, 2):
			var offset = Vector2i(x, y)
			_port_rebind(coord + offset)
			


var _component_map: Dictionary[Vector2i, LogisticIOComponent] = {}
func get_logistic(coord: Vector2i)-> LogisticIOComponent:
	return _component_map.get(coord, null)

func set_logistic(coord: Vector2i, com: LogisticIOComponent):
	_component_map.set(coord, com)

func erase_logistic(coord: Vector2i):
	_component_map.erase(coord)

# ==============================================================================
# 3. 內部邏輯
# ==============================================================================
func _port_rebind(coord: Vector2i):
	var comp: LogisticIOComponent = get_logistic(coord)
	if not comp:
		return 
	comp.port_rebind_ALG()


## Render item
func _process(_delta: float) -> void:
	queue_redraw()



func _draw() -> void:
	# 1. 收集所有物品到一個扁平的陣列中
	var all_items: Array[LineItem] = []
	
	for comp: LogisticIOComponent in _component_map.values():
		#if comp is not LogisticIO:
			#continue
		
		# append_array 比迴圈 append 更快
		all_items.append_array(comp.get_line_items())
	#print("Logistic components ", _component_map)

	# 2. 直接對「所有物品」進行座標排序 (Y 為主，X 為輔)
	# 這樣保證了 Y 座標較大 (下方) 的物品永遠會蓋住 Y 座標較小 (上方) 的物品
	all_items.sort_custom(func(a, b):
		var pos_a = a.get_position()
		var pos_b = b.get_position()

		# 計算「左下傾向」的分數
		# 公式：Y - X
		# 原因：Y 越大代表越下面(+)，X 越小代表越左邊(-)，所以 (Y - X) 數值越大代表越靠左下
		var score_a = pos_a.y - pos_a.x
		var score_b = pos_b.y - pos_b.x

		# 分數大的排前面 (左下優先)
		return score_a > score_b
	)

	# 3. 依序繪製
	for item in all_items:
		var pos = item.get_position()
		var texture = ItemDB.get_icon(item.type)
		var size = ItemDB.ICON_SIZE 
		
		var rect = Rect2(pos - size / 2.0, size)
		draw_texture_rect(texture, rect, false)












#
