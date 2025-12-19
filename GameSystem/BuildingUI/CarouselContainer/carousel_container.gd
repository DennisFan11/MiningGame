# ==============================================
# CarouselContainer.gd (Refactored)
# Godot 4.x / GDScript
# ==============================================
@tool
class_name CarouselContainer
extends Node2D

# ---- Signals ---------------------------------------------------------------
signal selection_changed(index: int, node: Node2D)

# ---- Config ---------------------------------------------------------------
const MOVE_TIME := 0.2
const VISIBLE_RANGE := 5
const SEP := 64.0 + 32.0

# ---- Exported -------------------------------------------------------------
# 方向枚舉
enum DIREACTION { HORIZONTAL, VERTICAL }
@export var direction: DIREACTION = DIREACTION.HORIZONTAL:
	set(value):
		direction = value
		_refresh()

# 內部索引（不導出，避免工具時誤操作），對外請用 move() / get_selected()
var index: int = 0

# ---- Internals ------------------------------------------------------------
var _dist_cache := {}

# ---- Lifecycle ------------------------------------------------------------
func _enter_tree() -> void:
	# 子結點增減時自動刷新
	if not child_entered_tree.is_connected(_on_child_changed):
		child_entered_tree.connect(_on_child_changed)
	if not child_exiting_tree.is_connected(_on_child_changed):
		child_exiting_tree.connect(_on_child_changed)

func _ready() -> void:
	_refresh()

# ---- Public API -----------------------------------------------------------
func move(delta_idx: int) -> void:
	var c := get_child_count()
	if c <= 0:
		index = 0
		return
	index = clampi(index + delta_idx, 0, c - 1)
	_refresh()
	# 同步子 Carousel（巢狀）
	for n in get_children():
		if n is CarouselContainer:
			(n as CarouselContainer).move(0)

func get_selected() -> Node2D:
	var c := get_child_count()
	if c <= 0:
		return null
	index = clampi(index, 0, c - 1)
	return get_child(index)

func refresh() -> void:
	# 對外暴露顯式刷新（等價於 _refresh）
	_refresh()

# ---- Private --------------------------------------------------------------
func _on_child_changed(_child: Node) -> void:
	_refresh()

func _refresh() -> void:
	var c := get_child_count()
	if c <= 0:
		index = 0
		return
	index = clampi(index, 0, c - 1)
	_update_children_layout()
	emit_signal("selection_changed", index, get_child(index))

func _update_children_layout() -> void:
	var c := get_child_count()
	if c <= 0:
		return

	# 清掉已刪除 child 的快取
	var current := get_children()
	for k in _dist_cache.keys():
		if not current.has(k):
			_dist_cache.erase(k)

	var radius = max(0.0, VISIBLE_RANGE / 2.0)

	for i in c:
		var child := get_child(i)
		# 目標位置
		var offset := (i - index) * SEP
		var target_pos = Vector2(offset, 0.0) if (direction == DIREACTION.HORIZONTAL) \
			  else Vector2(0.0, -offset)

		# 位置 Tween
		var tween := get_tree().create_tween()
		tween.tween_method(_child_move.bind(child), child.position, target_pos, MOVE_TIME)

		# 距離→可見性/縮放
		var dist = abs(i - index)
		var t := 1.0 if radius == 0.0 else (1.0 - clampf(float(dist) / radius, 0.0, 1.0))
		var tween2 := get_tree().create_tween()
		tween2.tween_method(_child_set.bind(child), _dist_cache.get(child, 0.0), t, MOVE_TIME)
		_dist_cache[child] = t

func _child_move(pos: Vector2, child: Node2D) -> void:
	child.position = pos

@export var remap_curve: Curve

func _child_set(re_map_dist: float, child: Node2D) -> void:
	if remap_curve:
		re_map_dist = remap_curve.sample_baked(clampf(re_map_dist, 0.0, 1.0))
	child.modulate = Color(1, 1, 1, re_map_dist)
	child.visible = re_map_dist > 0.01

	# 僅放大：被選中的列裡，被選中的項
	if get_parent() is CarouselContainer \
	and get_selected() == child \
	and (get_parent() as CarouselContainer).get_selected() == self:
		child.scale = Vector2.ONE * (1.0 + 0.2 * re_map_dist)
	else:
		child.scale = Vector2.ONE

func _addition_update() -> void:
	pass
