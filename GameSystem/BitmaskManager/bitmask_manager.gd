class_name BitmaskManager
extends Node2D


func _ready() -> void:
	DI.register("_bitmask_manager", self)


enum TEAM { IDLE, PLAYER, ENEMY }
const WALL_LAYER: int   = 1 << 0
const PLAYER_LAYER: int = 1 << 1
const ENEMY_LAYER: int  = 1 << 4



## 獲取中立牆 bitmask (通常用於尋路)
func get_wall_layer(team: TEAM)-> int:
	return WALL_LAYER

## 獲取給定 team 的友軍的 bitmask
func get_self_layer(team: TEAM)-> int:
	return PLAYER_LAYER if team==TEAM.PLAYER else ENEMY_LAYER

## 獲取給定 team 敵人的 bitmask
func get_enemy_layer(team: TEAM)-> int:
	return ENEMY_LAYER if team==TEAM.PLAYER else PLAYER_LAYER


#
