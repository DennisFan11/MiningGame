class_name PropHolderComponent
extends Component

var __body_component: BodyComponent

# 依賴
var _prop_manager: PropManager
var _bitmask_manager: BitmaskManager

# 內部組件
var _pickup_area: Area2D

# 狀態同步
@export var current_prop_id: int = -1:
	set(value):
		current_prop_id = value
		_update_held_visual(value)
var _held_entity: Entity

# Data
func _on_data_set(_data: ComponentData):
	pass

func _process(_delta: float) -> void:
	_pickup_area.global_position = __body_component.body.global_position

func _on_setuped():
	_pickup_area = Area2D.new()
	_pickup_area.name = "PickupArea"
	_pickup_area.collision_layer = 0
	_pickup_area.collision_mask = _bitmask_manager.get_prop_layer() # Prop Layer
	_pickup_area.modulate = Color.AQUAMARINE
	
	var shape = CircleShape2D.new()
	shape.radius = 100.0
	var collider = CollisionShape2D.new()
	collider.shape = shape
	_pickup_area.add_child(collider)
	add_child(_pickup_area)
	
	# MultiplayerSynchronizer for Late Joiners
	var synchronizer = NetworkSynchronizer.new()
	synchronizer.name = "PropHolderSynchronizer"
	
	# Config Replication
	synchronizer.add_property(NodePath(":current_prop_id"))
	
	# Set Authority (Server controls this)
	synchronizer.set_multiplayer_authority(1)
	
	add_child(synchronizer)
	
	if not multiplayer.is_server():
		synchronizer.start()

# API
func try_pickup():
	if not is_multiplayer_authority(): return
	var target = _find_nearest_prop()
	print("player pickup", target)
	if target:
		rpc_try_pickup.rpc_id(1, target.get_path())

func try_throw(target_pos: Vector2):
	if not is_multiplayer_authority(): return
	rpc_try_throw.rpc_id(1, target_pos)

# RPCs
@rpc("any_peer", "call_local", "reliable")
func rpc_try_pickup(target_path: NodePath):
	if not multiplayer.is_server(): return
	var target_body = get_node_or_null(target_path)
	if not target_body: return
	
	if __body_component.body.global_position.distance_to(target_body.global_position) > 150.0:
		printerr("player pickup distan too long")
		return
	
	
	if target_body is not RigidBody2D:
		return
	if target_body.get_parent() is not PropBodyComponent:
		return
	if target_body.get_parent() is not PropBodyComponent:
		return
		
	var prop_body_comp = target_body.get_parent()
	var data = prop_body_comp.get_prop_data()
	print("player pickup data: ", data)
	
	if data:
		var id = _find_prop_id(data)
		
		if id != -1:
			# User allows knowing Entity for freeing
			# PropBodyComponent -> Entity
			prop_body_comp.remove_entity()
			current_prop_id = id # Setter triggers visual update local & sync triggers remote


@rpc("any_peer", "call_local", "reliable")
func rpc_try_throw(target_pos: Vector2):
	if not multiplayer.is_server(): return
	if current_prop_id == -1: return
		
	var dir = (target_pos - __body_component.body.global_position).normalized()
	var force = dir * 500.0
	
	if _prop_manager:
		_prop_manager.spawn_prop(current_prop_id, __body_component.body.global_position + dir * 30.0, force)
	
	current_prop_id = -1 # Setter triggers visual update local & sync triggers remote

func _update_held_visual(id: int):
	if is_instance_valid(_held_entity):
		_held_entity.queue_free()
		_held_entity = null
		
	if id == -1: return
	
	# 使用 HELD Factory (Facade with State)
	var data = PropDB.get_data(id)
	if not data: return

	# Use Explicit Factory for Held Prop
	var entity = PropDB.create_held_prop(data)
	if entity:
		add_child(entity)
		_held_entity = entity

func _find_nearest_prop() -> Node:
	if not _pickup_area: return null
	var bodies = _pickup_area.get_overlapping_bodies()
	var nearest: Node = null
	var min_dist = INF
	for body in bodies:
		var dist = __body_component.body.global_position.distance_to(body.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = body
	return nearest

func _find_prop_id(data: PropData) -> int:
	for key in PropDB.props.keys():
		if PropDB.props[key] == data:
			return key
	return -1
