class_name BuildingManager
extends Node2D


var _spawner: NetworkSpawner

func _enter_tree() -> void:
	_spawner = NetworkSpawner.new()
	_spawner.name = "BuildingNetworkSpawner"
	_spawner.spawn_function = _spawn_building_node
	add_child(_spawner)

func _ready() -> void:
	DI.register("_building_manager", self)
	# BuildingManager 的 spawn_path 設定
	# 原本是 _spawner.spawn_path = %_building_node.get_path()
	# NetworkSpawner 的 spawn_path 是 NodePath，需要相對於 NetworkSpawner 或是絕對路徑
	# 因為我們剛剛 add_child(_spawner) 到 BuildingManager
	# 所以如果 %_building_node 是 BuildingManager 的子節點，我們需要正確設定路徑
	# 這裡建議直接使用 get_node("%_building_node").get_path() 來獲取絕對路徑或相對路徑
	# 但考慮到 NetworkSpawner 是在 _enter_tree 加入的，此時 %UniqueName 可能還可以存取
	
	# 為了保險，我們在 _ready 設定 spawn_path
	var building_node = get_node("%_building_node") # 假設 _building_node 是 Unique Name
	if building_node:
		_spawner.spawn_path = building_node.get_path()
	else:
		push_error("BuildingManager: %_building_node not found!")

var _terrain_manager: TerrainManager

func get_block(coord: Vector2i) -> BuildingEntity:
	return _block_map.get(coord, null)

func is_space(coord: Vector2i) -> bool:
	return _block_map.get(coord, null) == null \
		and _terrain_manager.get_terrain(coord - Vector2i.ONE) == TerrainManager.TERRAIN_TYPE.AIR

# Spawner Factory
func _spawn_building_node(data: Dictionary) -> Node:
	var type = data.get("type")
	var data_uid = data.get("data_uid")
	var state_dict = data.get("state")
	
	var data_script = load(data_uid)
	var building_data = data_script.new()
	var state = BuildingState.from_dict(state_dict)
	
	var instance = BuildingDB.create_type(type, building_data, state)
	
	if data.has("items") and instance is BuildingConstruct:
		instance.contain_item.item_set = data["items"]
		instance.update_progress()
	
	return instance

# Register (called by Entity._ready)
func register_building(building: BuildingEntity):
	_block_map[building.state.coord] = building
	# print("Registered building at ", building.state.coord)

# ==============================================================================
# 2. 公開 API - 強制操作 (Server Only)
# ==============================================================================

func spawn_building(type: int, data: BuildingData, state: BuildingState, items: Dictionary = {}):
	if not multiplayer.is_server():
		push_error("Client try to spawn building!")
		return
		
	var pack = {
		"type": type,
		"data_uid": data.get_script().resource_path,
		"state": state.to_dict()
	}
	if not items.is_empty():
		pack["items"] = items

	_spawner.spawn(pack)

## 刪除建築
func delete_block(coord: Vector2i):
	if not multiplayer.is_server(): return
	
	var building: BuildingEntity = get_block(coord)
	if not building:
		return
	
	# Spawner Note: queue_free on Server automatically syncs deletion
	building.queue_free()
	_block_map.erase(coord)


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
static func snap_pos(global_pos: Vector2) -> Vector2:
	return snapped(global_pos + BLOCK_SIZE / 2.0, BLOCK_SIZE) - BLOCK_SIZE / 2.0

## 將矩形對齊到方格邊界（用於區域選取或碰撞框對齊）
func ceil_pos(global_pos: Vector2) -> Vector2:
	return (global_pos / BLOCK_SIZE).ceil() * BLOCK_SIZE

func floor_pos(global_pos: Vector2) -> Vector2:
	return (global_pos / BLOCK_SIZE).floor() * BLOCK_SIZE

# 將世界座標轉換成方格座標（整數索引）
static func global_pos_to_coord(global_pos: Vector2) -> Vector2i:
	return (snap_pos(global_pos) + BLOCK_SIZE / 2.0) / BLOCK_SIZE

static func coord_to_global(coord: Vector2i) -> Vector2:
	return Vector2(coord) * BLOCK_SIZE - BLOCK_SIZE / 2.0


## 工具區


var _block_map: Dictionary[Vector2i, BuildingEntity] = {}


#
