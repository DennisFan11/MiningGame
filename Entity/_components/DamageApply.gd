class_name DamageApply
extends Node2D


func get_damage_taker(body: Node2D)-> DamageTaker:
	#print(body.get_children())
	for i in body.get_children():
		if i is DamageTaker:
			return i
	return null

var _debug_draw: DebugDraw
var _terrain_manager: TerrainManager
var _particle_manager: ParticleManager
var _hitted_buffer: Dictionary[Vector2i, bool] = {}

func damage_terrain(global_pos: Vector2, damage: float, dir: Vector2=Vector2.ZERO):
	var coord: Vector2i =\
		 _terrain_manager.global_to_coord(global_pos)
		
	_particle_manager.create(
		ParticleManager.TYPE.SPARK,
		global_pos,
		dir.angle(),
		true
	)
	
	if _hitted_buffer.has(coord):
		return 
	_hitted_buffer[coord] = true
	
	
	_debug_draw.d_draw_circle(
		global_pos, 10, Color.RED, 2.0
	)
	
	
	
	_terrain_manager.hit_terrain(coord, damage)






func clear_hitted_buffer():
	_hitted_buffer = {}
