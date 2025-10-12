class_name BulletManager
extends Node2D



func _ready() -> void:
	DI.register("_bullet_manager", self)



enum BULLET_TYPE {NORMAL}

var _bullet_map: Dictionary[BULLET_TYPE, PackedScene] = {
	BULLET_TYPE.NORMAL: preload("uid://bvsu0onyi5npf")
}


func spawn_bullet(type: BULLET_TYPE, config: BulletConfig):
	var bullet: Bullet = _bullet_map[type].instantiate()
	bullet.spawn(config)
	add_child(bullet)
