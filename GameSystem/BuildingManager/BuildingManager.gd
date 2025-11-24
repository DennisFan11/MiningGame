class_name BuildingManager
extends Node2D


func _ready() -> void:
	DI.register("_building_manager", self)

"""
建築管理器 位於系統內核 API需保持簡潔
使用 coord & BuildingI

"""



# ==============================================================================
# 1. 公開 API - 查詢 (Queries)
# ==============================================================================


var _terrain_manager: TerrainManager

func get_block(coord: Vector2i)-> BuildingI:
	return _block_map.get(coord, null)

func is_space(coord: Vector2i)-> bool:
	return _block_map.get(coord, null)==null\
		and _terrain_manager.get_terrain(coord -Vector2i.ONE) == TerrainManager.TERRAIN_TYPE.AIR





# ==============================================================================
# 2. 公開 API - 強制操作 (Actions)
# ==============================================================================

func set_block(
	coord: Vector2i,
	building: BuildingI
	):
	print("set_block(" + str(coord) +str(building.data)+")")
	
	## 強制放置
	delete_block(coord)
	delete_terrain(coord)
	
	_block_map[coord] = building
	%_building_node.add_child(building)
	return building


## 刪除建築
func delete_block(coord: Vector2i):
	var building: BuildingI = get_block(coord)
	if not building:
		return 
	building.queue_free()
	_block_map[coord] = null

## 移除地形
func delete_terrain(coord: Vector2i):
	_terrain_manager.set_terrain(
		_terrain_manager.global_to_coord(
			coord_to_global(coord)),
			TerrainManager.TERRAIN_TYPE.AIR
		)



func fetch():
	pass







# ==============================================================================
# 3. 座標換算 API - 強制操作 (Actions)
# ==============================================================================


const BLOCK_SIZE := Vector2.ONE * 64.0

## 將世界座標對齊到最近的方格邊界
## 加上 BLOCK_SIZE / 2.0 是為了以格中心為基準對齊，而非左上角
static func snap_pos(global_pos: Vector2)-> Vector2:
	return snapped(global_pos+ BLOCK_SIZE/2.0, BLOCK_SIZE) - BLOCK_SIZE/2.0

## 將矩形對齊到方格邊界（用於區域選取或碰撞框對齊）
func ceil_pos(global_pos: Vector2)-> Vector2:
	return (global_pos/BLOCK_SIZE).ceil() * BLOCK_SIZE

func floor_pos(global_pos: Vector2)-> Vector2:
	return (global_pos/BLOCK_SIZE).floor() * BLOCK_SIZE

# 將世界座標轉換成方格座標（整數索引）
static func global_pos_to_coord(global_pos: Vector2)-> Vector2i:
	return (snap_pos(global_pos)+ BLOCK_SIZE/2.0) / BLOCK_SIZE

static func coord_to_global(coord: Vector2i)-> Vector2:
	return Vector2(coord) * BLOCK_SIZE - BLOCK_SIZE/2.0




## 工具區



var _block_map: Dictionary[Vector2i, BuildingI] = {}










#
