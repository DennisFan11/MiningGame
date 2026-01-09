class_name IFF
extends Node2D

## IFF 敵我識別組件 (Standard Node)
## 提供 Area2D 碰撞檢測，供 Builder 等系統偵測目標

# === TARGET flags ===
enum TARGET {
	BE_SCANNED = 1 << 0, # 1
	SCAN_ALLY = 1 << 1, # 2
	SCAN_WALL = 1 << 2, # 4
	SCAN_ENEMY = 1 << 3 # 8
}

# === 全域 DI ===
var _bitmask_manager: BitmaskManager

# === 配置屬性 ===
@export var team: BitmaskManager.TEAM = BitmaskManager.TEAM.IDLE:
	set(value):
		team = value
		_refresh_area()

@export_flags("BE_SCANNED", "SCAN_ALLY", "SCAN_WALL", "SCAN_ENEMY")
var target: int = 0:
	set(value):
		target = value
		_update_area_layers_and_masks()

@export var radius: float = 64.0:
	set(value):
		radius = value
		_resize_area()

# === 內部狀態 ===
var _area: Area2D = null

# === 初始化 ===

func setup(p_team: BitmaskManager.TEAM, p_target: int, p_radius: float):
	team = p_team
	target = p_target
	radius = p_radius

func _enter_tree():
	# 嘗試自動注入依賴
	if not _bitmask_manager:
		DI.injection(self)

func _on_injected():
	# DI 回調 (若被 DI 呼叫)
	_refresh_area()

func _ready():
	_try_build_area()

# === Public API ===

func get_area() -> Area2D:
	return _area

## 獲取所有偵測到的目標（返回其 master/owner）
func get_targets() -> Array[Node2D]:
	var nodes: Array[Node2D] = []
	if not _area:
		return nodes

	for a in _area.get_overlapping_areas():
		var parent = a.get_parent()
		# 僅處理 IFF，排除自己
		if parent is IFF and parent != self:
			var owner_node = parent.get_owner_node()
			if owner_node:
				nodes.append(owner_node)
	
	# 去重
	var seen := {}
	var unique: Array[Node2D] = []
	for n in nodes:
		if not seen.has(n):
			seen[n] = true
			unique.append(n)
	return unique

## 依距離排序的目標列表
func get_sorted_targets(from: Vector2) -> Array[Node2D]:
	var arr = get_targets()
	arr.sort_custom(
		func(a: Node2D, b: Node2D):
			return a.global_position.distance_to(from) < b.global_position.distance_to(from)
	)
	return arr

## 獲取此組件的擁有者節點（向上搜尋）
func get_owner_node() -> Node2D:
	var parent = get_parent()
	while parent:
		if parent is Node2D and not parent is Component and not parent is IFF:
			return parent
		parent = parent.get_parent()
	return null

# === 內部方法 ===

func _try_build_area():
	if _area or not _bitmask_manager or team == BitmaskManager.TEAM.IDLE:
		return
	
	_area = _create_area(radius)
	add_child(_area)
	_area.monitoring = true
	_area.monitorable = true
	_update_area_layers_and_masks()

func _create_area(r: float) -> Area2D:
	var area = Area2D.new()
	var collide = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = r
	collide.shape = shape
	collide.name = "CollisionShape2D"
	area.add_child(collide)
	# Viz for debug
	area.modulate = Color(1, 1, 0, 0.3)
	return area

func _refresh_area():
	if team == BitmaskManager.TEAM.IDLE:
		if _area:
			_area.queue_free()
			_area = null
		return
	
	if not _bitmask_manager:
		return
	
	if not _area:
		_try_build_area()
	else:
		_update_area_layers_and_masks()

func _resize_area():
	if not _area:
		return
	
	var cs = _area.get_node_or_null("CollisionShape2D")
	if cs and cs.shape is CircleShape2D:
		cs.shape.radius = radius
	else:
		_area.queue_free()
		_area = null
		_try_build_area()

func _update_area_layers_and_masks():
	if not _area or not _bitmask_manager:
		return

	_area.collision_layer = 0
	_area.collision_mask = 0

	# 被掃描：放上自家層
	if target & TARGET.BE_SCANNED:
		_area.collision_layer |= _bitmask_manager.get_self_layer(team)

	# 掃描友軍
	if target & TARGET.SCAN_ALLY:
		_area.collision_mask |= _bitmask_manager.get_self_layer(team)
		_area.collision_layer |= _bitmask_manager.get_self_layer(team)
	
	# 掃描牆壁
	if target & TARGET.SCAN_WALL:
		_area.collision_mask |= _bitmask_manager.get_wall_layer(team)
		_area.collision_layer |= _bitmask_manager.get_wall_layer(team)
	
	# 掃描敵軍
	if target & TARGET.SCAN_ENEMY:
		_area.collision_mask |= _bitmask_manager.get_enemy_layer(team)
		_area.collision_layer |= _bitmask_manager.get_enemy_layer(team)
