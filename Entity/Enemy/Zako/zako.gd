class_name Enemy
extends CharacterBody2D




var _player: Player
var _debug_draw: DebugDraw
var _bitmask_manager: BitmaskManager

## TOOLs

## 向玩家發射射線 
func can_see_player()-> bool:
	var from  = global_position
	var to = _player.get_player_position()
	var dict := Utility.raycast_once(
		self, 
		from, 
		to,
		_bitmask_manager.PLAYER_LAYER | _bitmask_manager.WALL_LAYER
	)
	
	var result:bool = false
	if dict.has("collider"):
		if dict["collider"].get_parent() is Player:
			result = true

	_debug_draw.add_draw(func ():
		_debug_draw.draw_line(
			from, 
			dict["position"]if dict.has("collider") else to,
			Color.GREEN if result else Color.CRIMSON,
			4.0
		),
		0.2
	)
	return result
	
	
## 檢測自身與牆壁距離
func _scan_wall_dist(vec: Vector2)-> float:
	var from = global_position
	var to = global_position + vec
	var res: Dictionary = Utility.raycast_once(
		self,
		from,
		to,
		_bitmask_manager.WALL_LAYER,
	)
	
	## 未命中
	if not res.has("collider"):
		return vec.length()
	#print(res["collider"])
	_debug_draw.add_draw(func():
		_debug_draw.draw_line(
			from,
			res["position"],
			Color.REBECCA_PURPLE,
			3.0
		),
		0.3
	)
	return (res["position"] - global_position).length()
	
## 尋找空曠的地方返回相對向量
## angle : 面向的方向
## _range: 扇形角度
func find_clear_direction(angle: float, _range: float=PI/2.0)-> Vector2:
	const RAY_COUNT: int = 5
	const RAY_DIST: float = 999.0
	var SINGLE_ADD: float = _range/RAY_COUNT
	
	var _max_vec: Vector2 = Vector2.ZERO
	var _max_wall_dist: float = 0.0
	
	for _angle_count in range(RAY_COUNT):
		var _angle := angle + _angle_count * SINGLE_ADD - _range/2.0
		
		var vec = Vector2.from_angle(_angle) * RAY_DIST
		var dist = _scan_wall_dist(vec)
		if dist > _max_wall_dist:
			_max_wall_dist = dist
			_max_vec = vec 
			
	return _max_vec.normalized() * _max_wall_dist
	





const DECELERATION := 20.5
const ACCELERATION := 15.3
const MAX_SPEED = 150.0

func walk(dt: float, walk_pos: Vector2) -> void:

	# 計算向量與距離
	var to_target: Vector2 = walk_pos - global_position
	var distance: float = to_target.length()

	# 若距離非常小，慢慢減速到零；否則朝目標加速向最大速度靠攏
	if distance < 10.0:
		# 幾乎到達目標：往零速度靠攏（減速）
		velocity = velocity.lerp(Vector2.ZERO, DECELERATION * dt)
	else:
		# 正規化方向，計算目標速度向量
		var dir: Vector2 = to_target / distance
		var target_velocity: Vector2 = dir * MAX_SPEED
		# 用 lerp 實作平滑加速
		velocity = velocity.lerp(target_velocity, ACCELERATION * dt)

	move_and_slide()







#
