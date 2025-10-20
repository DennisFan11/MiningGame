@tool
class_name CarouselContainer
extends Node2D

@export_tool_button("ADD")
var ADD = func(): move(1)
@export_tool_button("SUB")
var SUB = func(): move(-1)

func _ready() -> void:
	_update_child()

enum DIREACTION {horizontal, vertal}
@export var direction: DIREACTION = DIREACTION.horizontal:
	set(new):
		direction = new
		_update_child()


var index :int = 2

const MOVE_TIME = 0.2

func move(mount: int):
	index = clampi(
		index+mount, 0, get_child_count()-1
	)
	_update_child()
	_addition_update()
	
	for i in get_children():
		if i is CarouselContainer:
			i.move(0)

func get_selected()-> Node2D:
	return get_child(index)

const VISIBLE_RANGE: int = 5

const SEP := 64.0 + 32.0
const CHILD_SIZE := Vector2(64, 64)

func _update_child() -> void:
	var radius = max(0.0, (VISIBLE_RANGE) / 2.0)
	
	for i in range(get_child_count()):
		var dist = abs(i - index)                 # 索引距離（整數即可）
		var child = get_child(i)
		
		# 位置保持原樣
		var offset = (i - index) * SEP
		var pos := \
			Vector2(offset, 0.0) if direction == DIREACTION.horizontal else Vector2(0.0, -offset)
		
		var tween = get_tree().create_tween()
		tween.tween_method(
			_child_move.bind(child), 
			child.position, 
			pos, 
			MOVE_TIME)
		
		#_child_move(pos, child)
		tween = get_tree().create_tween()
		# 將距離映射到 0~1（中心=1，邊界=0）；半徑為0時避免除零
		var t := 1.0 if radius == 0.0 else (1.0 - clampf(float(dist) / radius, 0.0, 1.0))
		
		# 傳入 _child_move：t 範圍 0~1
		tween.tween_method(
			_child_set.bind(child),
			_dist_cache.get(child, 0.0),
			t,
			MOVE_TIME)
		
		#_child_set(t, child)
		_dist_cache[child] = t
	

var _dist_cache = {}

func _child_move(pos: Vector2, child: Node2D):
	child.position = pos

@export var remap_curve: Curve


#@export var scale_curve: Curve

## dist 範圍 0 ~ 1
func _child_set(re_map_dist: float, child: Node2D):
	if remap_curve:
		re_map_dist = remap_curve.sample_baked(re_map_dist)
	child.modulate = Color(1, 1, 1, (re_map_dist))
	child.visible = re_map_dist > 0.0
	
	
	if  get_parent() is CarouselContainer and\
		get_selected() == child and \
		get_parent().get_selected() == self:
		child.scale = Vector2.ONE * (1.0 + 0.2*re_map_dist)
	else:
		child.scale = Vector2.ONE
		scale = Vector2.ONE








###

func _addition_update():
	pass









#
