class_name IFF
extends Node2D
"""
敵我碰撞檢測系統
設定 team, target 以初始化
"""


@export var team: BitmaskManager.TEAM = BitmaskManager.TEAM.IDLE:
	set(new):
		team = new
		_area_update()

@export_flags("BE_SCANNED:1","SCAN_ALLY:2","SCAN_WALL:4","SCAN_ENEMY:8")
var target: int = 0:
	set(new):
		target = new
		_area_update()

@export var master: Node2D

enum TARGET{
	BE_SCANNED = 1 << 1, 
	SCAN_ALLY = 1 << 2,
	SCAN_WALL = 1 << 3,
	SCAN_ENEMY= 1 << 4
}





func get_area()-> Area2D: return _area

func get_targets()-> Array[Node2D]:
	var nodes: Array[Node2D] = []
	
	if not _area:
		return nodes
	
	for i in _area.get_overlapping_areas():
		var t = i.get_parent()
		if t is IFF:
			if t.master:
				nodes.append(t)
	return nodes

## PRIVATE

var _area: Area2D = null
var _bitmask_manager: BitmaskManager

func _area_update()-> void:
	if team == BitmaskManager.TEAM.IDLE:
		return
	
	
	const AREA_R: float = 10.0
	
	if not _area:
		_area = Utility.create_area(AREA_R)
		add_child(_area)
	_area.collision_layer = 0
	_area.collision_mask = 0
	
	if target & TARGET.BE_SCANNED:
		_area.collision_layer |= _bitmask_manager.get_self_layer(team)
	if target & TARGET.SCAN_ALLY:
		_area.collision_mask |= _bitmask_manager.get_self_layer(team)
	if target & TARGET.SCAN_WALL:
		_area.collision_mask |= _bitmask_manager.get_wall_layer(team)
	if target & TARGET.SCAN_ENEMY:
		_area.collision_mask |= _bitmask_manager.get_enemy_layer(team)










#
