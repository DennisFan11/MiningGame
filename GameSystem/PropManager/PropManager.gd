class_name PropManager
extends Node2D

@onready var _spawner: NetworkSpawner

func _enter_tree() -> void:
	# 動態建立 NetworkSpawner，不依賴場景中的節點
	_spawner = NetworkSpawner.new()
	_spawner.name = "PropNetworkSpawner"
	# 設定 spawn_path 為 PropManager 自己 (因為 props 是 PropManager 的子節點)
	# 使用 get_path() 獲取絕對路徑，確保 NetworkSpawner 能正確找到 PropManager
	_spawner.spawn_path = get_path()
	_spawner.spawn_function = _spawn_prop_node
	add_child(_spawner)

func _ready() -> void:
	DI.register("_prop_manager", self)
	
	# 如果場景中有舊的 PropSpawner，將其釋放以免干擾 (Optional)
	if has_node("PropSpawner"):
		get_node("PropSpawner").queue_free()

func _game_start():
	# Client 端啟動 NetworkSpawner 同步
	if not multiplayer.is_server():
		_spawner.start()

	## Spawn TEST 
	if multiplayer.is_server():
		#await get_tree().create_timer(10).timeout
		spawn_prop(PropDB.PROP.STONE, Vector2.ZERO)


# ==============================================================================
# Public API (Server Only)
# ==============================================================================

func spawn_prop(id: int, pos: Vector2, force: Vector2 = Vector2.ZERO):
	if not multiplayer.is_server():
		push_error("PropManager: spawn_prop called on client")
		return
		
	var data = {
		"id": id,
		"pos": pos,
		"force": force
	}
	# NetworkSpawner.spawn 回傳 Node，這裡我們不需要接回傳值
	_spawner.spawn(data)

# ==============================================================================
# Internal (Spawn Function)
# ==============================================================================

const BodyDataScript = preload("res://Entity/ComponentSystem/Prop/PropBody/PropBodyComponentData.gd")

func _spawn_prop_node(data: Dictionary) -> Node:
	var id = data.get("id")
	var pos = data.get("pos", Vector2.ZERO)
	var force = data.get("force", Vector2.ZERO)
	
	var prop_data = PropDB.get_data(id)
	if not prop_data: return null
	
	# Create World Prop (Facade handles State creation)
	var entity = PropDB.create_world_prop(prop_data, pos, force)
		
	return entity
