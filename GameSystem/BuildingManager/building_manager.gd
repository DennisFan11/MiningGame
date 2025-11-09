class_name BuildingManager
extends Node2D


func _ready() -> void:
	DI.register("_building_manager", self)



enum TYPE{ PLAN, CONSTRUCT, BUILDING }
func try_set_block(coord: Vector2i,
	data: BuildingData,
	team: BitmaskManager.TEAM,
	type: TYPE
	):
		
	var ori_build: BuildingI = get_block(coord)
	## 直接放置情況
	if not ori_build:
		return set_block(coord, data, team, type)
	return







func set_block(
	coord: Vector2i,
	data: BuildingData,
	team: BitmaskManager.TEAM,
	type: TYPE
	):
	
	var instance: BuildingI = null
	print_stack()
	#data.coord = coord
	print("set_block(" + str(coord) +str(data)+")")
	match type:
		TYPE.PLAN:
			print("PLAN")
			instance = BuildingDB.create_plan(data)
		TYPE.CONSTRUCT:
			print("CONSTRUCT")
			instance = BuildingDB.create_construct(data)
		TYPE.BUILDING:
			print("BUILDING")
			instance = BuildingDB.create_building(data)
		_:
			return
	
	instance.coord = coord
	instance.team = team
	
	var ori_build: BuildingI = _block_map.get(coord, null)
	## 直接放置
	if ori_build:
		ori_build.queue_free()
	
	_block_map[coord] = instance
	add_child(instance)
	return instance









func get_block(coord: Vector2i)-> BuildingI:
	return _block_map.get(coord, null)



## 相關操作

func _remove(coord):
	_block_map.erase(coord)
	

func fetch():
	pass













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


func _vaild_check():
	pass


var _block_map: Dictionary[Vector2i, BuildingI] = {}










#
