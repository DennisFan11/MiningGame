class_name TerrainManager
extends Node2D

func _ready() -> void:
	DI.register("_terrain_manager", self)


enum TERRAIN_TYPE { AIR, WALL}
var terrain_map = {
	TERRAIN_TYPE.AIR: Vector2i(-1, -1),
	TERRAIN_TYPE.WALL: Vector2i(0, 1)
}



func get_terrain(coord: Vector2i)-> TERRAIN_TYPE:
	var id = %WallLayer.get_cell_atlas_coords(coord)
	if id == terrain_map[TERRAIN_TYPE.AIR]:
		return TERRAIN_TYPE.AIR
	return TERRAIN_TYPE.WALL



func set_terrain(coord: Vector2i, type:TERRAIN_TYPE)-> void:
	%WallLayer.set_cell(coord, -1, terrain_map[type])
	_hp_map.erase(coord)







var _hp_map: Dictionary[Vector2i, float] = {}

func get_hp(coord: Vector2i)-> float:
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
		set_terrain(coord, TERRAIN_TYPE.AIR)






## Math

func global_to_coord(global_pos: Vector2)-> Vector2i:
	return %WallLayer.local_to_map(%WallLayer.to_local(global_pos))
