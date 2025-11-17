class_name IFF
extends Node2D
"""
敵我碰撞檢測系統
設定 team, target（旗標）以初始化掃描/被掃描層與遮罩
"""

var master: Node2D:
	get:
		return get_parent()

# 從第 0 位開始（建議省略索引，Godot 會自動給 0,1,2,3）
@export_flags("BE_SCANNED", "SCAN_ALLY", "SCAN_WALL", "SCAN_ENEMY")
var target: int = 0:
	set(value):
		target = value
		_update_area_layers_and_masks()

enum TARGET{
	BE_SCANNED = 1 << 0,  # 1
	SCAN_ALLY  = 1 << 1,  # 2
	SCAN_WALL  = 1 << 2,  # 4
	SCAN_ENEMY = 1 << 3  # 8
}

@export var team: BitmaskManager.TEAM = BitmaskManager.TEAM.IDLE:
	set(value):
		team = value
		_refresh_area()

@export var AREA_R: float = 10.0:
	set(value):
		AREA_R = value
		_resize_area()

## PRIVATE
var _area: Area2D = null
var _bitmask_manager: BitmaskManager = null

func get_area() -> Area2D:
	return _area

func get_targets() -> Array[Node2D]:
	var nodes: Array[Node2D] = []
	if not _area:
		return nodes

	for a in _area.get_overlapping_areas():
		var t := a.get_parent()
		# 僅處理 IFF、排除自己
		if t is IFF and t != self:
			# 若需要「操作者」而非 IFF 節點本身，優先回 master
			if t.master:
				nodes.append(t.master)
			else:
				nodes.append(t)
	# 去重（以參考為準）
	var uniq := {}
	var out: Array[Node2D] = []
	for n in nodes:
		if not uniq.has(n):
			uniq[n] = true
			out.append(n)
	return out

func get_sorted_targets(from: Vector2) -> Array[Node2D]:
	var arr = get_targets()
	arr.sort_custom(
		func (A:Node2D, B: Node2D):
			return A.global_position.distance_to(from)\
				 < B.global_position.distance_to(from)
	)
	return arr



func _ready() -> void:
	# 若遊戲流程不是走 _game_start，也能在 ready 後工作
	_try_build_area()

func _on_injected() -> void:
	# 假設 DI 在這裡把 _bitmask_manager 指好
	_refresh_area()

func _game_start() -> void:
	DI.injection(self)
	_refresh_area()

# === 內部：建立/更新 ===

func _try_build_area() -> void:
	if _area or not _bitmask_manager or team == BitmaskManager.TEAM.IDLE:
		return
	_area = Utility.create_area(AREA_R)
	add_child(_area)
	# 依需要：確保監測開啟（若 Utility 未處理）
	_area.monitoring = true
	_area.monitorable = true
	_update_area_layers_and_masks()

func _refresh_area() -> void:
	# team 變動：IDLE -> 移除；其他 -> 確保存在並更新
	if team == BitmaskManager.TEAM.IDLE:
		if _area:
			_area.queue_free()
			_area = null
		return
	# 非 IDLE：若未注入 BM 就先不建
	if not _bitmask_manager:
		return
	if not _area:
		_try_build_area()
	else:
		_update_area_layers_and_masks()

func _resize_area() -> void:
	if _area:
		# 假設 Utility.create_area 內建形狀，直接調半徑；若無，請改為重建
		var cs := _area.get_node_or_null("CollisionShape2D")
		if cs and cs.shape is CircleShape2D:
			cs.shape.radius = AREA_R
		else:
			# 不同形狀或取不到時，退回重建
			_area.queue_free()
			_area = null
			_try_build_area()

func _update_area_layers_and_masks() -> void:
	if not _area or not _bitmask_manager:
		return

	_area.collision_layer = 0
	_area.collision_mask  = 0

	# 被掃描（讓別人看得到自己）：把自己放上相應的「自家層」
	if target & TARGET.BE_SCANNED:
		_area.collision_layer |= _bitmask_manager.get_self_layer(team)

	# 掃描友軍／牆／敵軍：把遮罩指向要「看的」那些層
	if target & TARGET.SCAN_ALLY:
		_area.collision_mask |= _bitmask_manager.get_self_layer(team)
		_area.collision_layer |= _bitmask_manager.get_self_layer(team)
	if target & TARGET.SCAN_WALL:
		_area.collision_mask |= _bitmask_manager.get_wall_layer(team)
		_area.collision_layer |= _bitmask_manager.get_wall_layer(team)
	if target & TARGET.SCAN_ENEMY:
		_area.collision_mask |= _bitmask_manager.get_enemy_layer(team)
		_area.collision_layer |= _bitmask_manager.get_enemy_layer(team)
