class_name LineItem
extends Resource

var gap: float   # 距離前方的空隙
var type: int    # 假設 Item.ITEM 是 int 或 enum

var line_provider: LineProvider


func _init(
		_gap: float, 
		_type: int, 
		_line_provider: LineProvider=null
	):
	gap = _gap
	type = _type
	line_provider = _line_provider



var progress_cache: float = 0.0

func get_position()-> Vector2:
	return line_provider.samp(progress_cache)
