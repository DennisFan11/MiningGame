extends Weapon


var _bullet_manager: BulletManager
var _sound_manager: SoundManager
var _camera: Camera

func _attack():
	_bullet_manager.spawn_bullet(
		BulletManager.BULLET_TYPE.NORMAL,
		_build_config()
		)
	_fire_sound()
	_camera.shake(0.2)






func _build_config()-> BulletConfig:
	var config = BulletConfig.new()
	config.dir = Vector2.from_angle(global_rotation)
	config.global_pos = %Marker2D.global_position
	return config

func _fire_sound():
	var sound = preload("res://Entity/Weapon/Gun/Gun_sound.wav")
	_sound_manager.play_sound(sound, %Marker2D.global_position)
