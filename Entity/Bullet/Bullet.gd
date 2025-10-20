class_name Bullet
extends CharacterBody2D

## 子彈速度 pix/s
const BULLET_SPEED: float = 1500.0
const BULLET_DAMAGE: float = 30.0


var _light_manager: LightManager
## 外部接口
func spawn(bullet_config: BulletConfig):
	_spawn(bullet_config)


func _ready() -> void:
	var light = _light_manager.create_light(1)
	%RemoteTransform2D.remote_path = light.get_path()
	tree_exited.connect(light.queue_free)

func _process(delta: float) -> void:
	_fly(delta)



## NOTE 複寫區


func _spawn(bullet_config: BulletConfig):
	position = bullet_config.global_pos
	_dir = bullet_config.dir
	rotation = _dir.angle()
	

var _dir: Vector2

func _fly(dt: float):
	velocity = _dir * BULLET_SPEED
	move_and_slide()
	#position += __target_vec * BULLET_SPEED * dt


func _hit(body: Node2D):
	if body is not CharacterBody2D:
		return
	
	var damage:DamageTaker = %DamageApply.get_damage_taker(body)
	if damage:
		damage.damage(BULLET_DAMAGE, global_position)
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	_hit(body)
