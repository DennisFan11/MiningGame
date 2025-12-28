class_name PropManager
extends Node2D

@onready var _spawner: MultiplayerSpawner = $PropSpawner

func _ready() -> void:
	DI.register("_prop_manager", self)
	
	_spawner.spawn_function = _spawn_prop_node

func _game_start():
	## Spawn TEST 
	if multiplayer.is_server():
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
