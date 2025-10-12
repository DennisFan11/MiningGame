class_name BitmaskManager
extends Node2D


func _ready() -> void:
	DI.register("_bitmask_manager", self)



const WALL_LAYER: int   = 1 << 0
const PLAYER_LAYER: int = 1 << 1
const ENEMY_LAYER: int  = 1 << 4




#
