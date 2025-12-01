class_name TransportLine
extends Node2D

# --- 定義輕量物品 ---
class LineItem:
	var gap: float   # 距離前方的空隙
	var type: int    # 假設 Item.ITEM 是 int 或 enum
	func _init(g: float, t: int): gap = g; type=t

# --- 參數 ---
const TOTAL_LEN: float = 32.0
const ITEM_SIZE: float = 8.0
const SPEED: float = 10.0

var _items: Array[LineItem] = []
var _stuck_idx: int = 0 

# [優化] 緩存變數：記錄當前所有 item.gap 的總和
var _cached_total_gaps: float = 0.0 

func line_update(delta: float) -> void:
	queue_redraw()
	
	if _items.is_empty() or _stuck_idx >= _items.size():
		return

	var item = _items[_stuck_idx]
	if item.gap > 0:
		# [核心修改 1] 計算實際減少量並更新緩存
		var reduction = min(item.gap, SPEED * delta) # 確保不會扣成負數
		item.gap -= reduction
		_cached_total_gaps -= reduction # 更新緩存
	else:
		_stuck_idx += 1

# --- 公開 API (外部呼叫) ---

func has_space() -> bool:
	return left_space() >= 0

# [優化] O(1) 計算：實體總長 + 緩存的空隙總長
func left_space()-> float: 
	var used_len = (_items.size() * ITEM_SIZE) + _cached_total_gaps
	return TOTAL_LEN - used_len

func try_add_item(item: LineItem) -> bool:
	var space = left_space()
	if space >= 0:
		item.gap = space
		_items.push_back(item)
		
		# [核心修改 2] 加入新物品的 Gap 到緩存
		_cached_total_gaps += item.gap
		
		if _items.size() == 1: _stuck_idx = 0
		return true
	return false

func try_take_item() -> LineItem:
	if _items.is_empty(): return null
	if _items[0].gap > 0.001: return null
	
	var item = _items.pop_front()
	
	# [核心修改 3] 移除物品時，扣除該物品殘留的極小 Gap (通常為 0)
	_cached_total_gaps -= item.gap 
	
	if not _items.is_empty():
		# 間隙補償：後方物品接收前方釋放的空間
		_items[0].gap += ITEM_SIZE
		
		# [核心修改 3] 緩存增加 (因為某個物品的 gap 變大了)
		_cached_total_gaps += ITEM_SIZE 
		
		_stuck_idx = 0
	else:
		# 為了防止浮點數誤差累積，清空時強制歸零
		_cached_total_gaps = 0.0 
		
	return item

# --- 視覺化 (保持不變) ---
const REAL_SIZE := Vector2(64, 32)
const FONT_RES := preload("uid://ixuq1j7jm0cv") # 修正變數名避免衝突
func _draw() -> void:
	draw_rect(Rect2(-REAL_SIZE/2, REAL_SIZE), Color(0.2, 0.2, 0.2))
	var RATIO = REAL_SIZE.x/TOTAL_LEN
	var OFFSET = -REAL_SIZE.x/2
	var x = TOTAL_LEN
	for item in _items:
		x -= item.gap 
		var pos = Vector2((x)*RATIO+OFFSET, 0)
		draw_circle(pos, 10, Color.WHEAT)
		# 這裡需確保 FONT_RES 有效，或暫時註解掉 draw_string
		if FONT_RES:
			draw_string(FONT_RES, pos, str(snapped(item.gap, 0.1)), HORIZONTAL_ALIGNMENT_CENTER, 20, 10, Color.BLACK)
		x -= ITEM_SIZE
