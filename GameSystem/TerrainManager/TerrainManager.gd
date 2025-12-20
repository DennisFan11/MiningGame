class_name TerrainManager
extends Node2D

func _ready() -> void:
	DI.register("_terrain_manager", self)


enum TERRAIN_TYPE {AIR, WALL}
var terrain_map = {
	TERRAIN_TYPE.AIR: Vector2i(-1, -1),
	TERRAIN_TYPE.WALL: Vector2i(0, 1)
}


func get_terrain(coord: Vector2i) -> TERRAIN_TYPE:
	var id = %WallLayer.get_cell_atlas_coords(coord)
	if id == terrain_map[TERRAIN_TYPE.AIR]:
		return TERRAIN_TYPE.AIR
	return TERRAIN_TYPE.WALL


@rpc("call_local")
func set_terrain(coord: Vector2i, type: TERRAIN_TYPE) -> void:
	%WallLayer.set_cell(coord, -1, terrain_map[type])
	_hp_map.erase(coord)


@rpc("any_peer")
func request_hit_terrain(coord: Vector2, damage: float):
	if not multiplayer.is_server(): return
	# 這裡假設傳入的是 Global Pos (因為 hit_terrain 原本參數是 Vector2)
	# 但原有邏輯似乎混用？為了保險，先轉成 Grid Coord
	var grid_coord = global_to_coord(coord)
	
	if get_terrain(grid_coord) == TERRAIN_TYPE.AIR:
		return
	
	_hit_effect.rpc(coord) # 全體播放特效
	set_hp(grid_coord, get_hp(grid_coord) - damage)

# Public Entry Point
func hit_terrain(coord: Vector2, damage: float):
	request_hit_terrain.rpc_id(1, coord, damage)

# ==============================================================================

var _hp_map: Dictionary[Vector2i, float] = {}

func get_hp(coord: Vector2i) -> float:
	if _hp_map.has(coord):
		return _hp_map.get(coord, 0.0)
	
	## reset hp
	var data: TileData = %WallLayer.get_cell_tile_data(coord)
	if data and data.has_custom_data("defult_hp"):
		set_hp(coord, data.get_custom_data("defult_hp"))
	return _hp_map.get(coord, 0.0)

func set_hp(coord: Vector2i, new: float):
	_hp_map.set(coord, new)
	if new <= 0.0:
		_hp_map.erase(coord)
		set_terrain.rpc(coord, TERRAIN_TYPE.AIR)


## effect
var _sound_manager: SoundManager
var _is_played_hit: bool = false
var _is_played_des: bool = false
func _process(delta: float) -> void:
	_is_played_hit = false
	_is_played_des = false


@rpc("call_local")
func _hit_effect(coord: Vector2):
	if _is_played_hit: return
	_is_played_hit = true
	_sound_manager.play_sound(
		[preload("uid://ckl0keggqg07a"), preload("uid://b5e7phc2kadbm")].pick_random(),
		# coord 若已經是 Global 則不用轉，若是 Grid 則要轉
		# 假設 request 傳入的是 Global
		coord
	)


## Math
func coord_to_global(coord: Vector2i) -> Vector2:
	return %WallLayer.to_global(%WallLayer.map_to_local(coord))
func global_to_coord(global_pos: Vector2) -> Vector2i:
	return %WallLayer.local_to_map(%WallLayer.to_local(global_pos))
