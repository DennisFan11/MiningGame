class_name PropBodyComponent
extends Component

# 內部變數 (Strict Naming: _property)
var __data: PropData

func get_prop_data() -> PropData:
	return __data

func remove_entity():
	if get_parent():
		get_parent().queue_free()

var _shape: Shape2D
var _mass: float = 1.0

# Initial State (Deferred Setup)
var _init_pos: Vector2 = Vector2.ZERO
var _init_force: Vector2 = Vector2.ZERO

var body: RigidBody2D
var _synchronizer: NetworkSynchronizer

# API for Factory (Resolves PropDB init timing issue)
func init_physics(pos: Vector2, force: Vector2):
	_init_pos = pos
	_init_force = force
	# If body already exists, apply immediately
	if body:
		_apply_init_state()

func _apply_init_state():
	if body:
		body.global_position = _init_pos
		if _init_force != Vector2.ZERO:
			body.apply_impulse(_init_force)

func _on_data_set(data: ComponentData):
	if data is PropBodyComponentData:
		_shape = data.shape
		_mass = data.mass

var _bitmask_manager: BitmaskManager

# Injected State: Removed

func _ready() -> void:
	# 建立物理實體 (Create early to satisfy dependencies like VisualComponent)
	body = RigidBody2D.new()
	body.name = "Body"
	body.mass = _mass
	body.gravity_scale = 0.0
	
	body.linear_damp_mode = RigidBody2D.DAMP_MODE_COMBINE
	body.linear_damp = 10.0
	
	body.physics_material_override = PhysicsMaterial.new()
	body.physics_material_override.bounce = 1.0
	
	# Note: Layer configuration deferred to _on_setuped because _bitmask_manager is not yet injected
	
	add_child(body)
	
	# Apply state if set early (unlikely but safe)
	_apply_init_state()

func _on_setuped():
	# Configure Body Dependencies
	if body and _bitmask_manager:
		var prop_layer = _bitmask_manager.get_prop_layer()
		body.collision_layer = prop_layer
		body.collision_mask = \
			prop_layer | \
			_bitmask_manager.get_wall_layer() | \
			_bitmask_manager.PLAYER_LAYER
	
	# Apply deferred state again just in case (rendering/physics frame timing)
	_apply_init_state()

	if _shape:
		var collider = CollisionShape2D.new()
		collider.shape = _shape
		body.add_child(collider)
	
	_setup_multiplayer_sync()
	
	# Check State via Injection: Removed
	# Config is handled externally via Component Access

# Note: _physics_process removed as we no longer sync Entity to Body

func _setup_multiplayer_sync():
	_synchronizer = NetworkSynchronizer.new()
	_synchronizer.name = "Synchronizer"
	_synchronizer.set_multiplayer_authority(1)
	_synchronizer.sync_every_frame = true
	
	_synchronizer.add_property(NodePath("Body:position"), true)
	_synchronizer.add_property(NodePath("Body:rotation"), true)
	_synchronizer.add_property(NodePath("Body:linear_velocity"), true)
	_synchronizer.add_property(NodePath("Body:angular_velocity"), true)
	
	add_child(_synchronizer)
	
	if not multiplayer.is_server():
		_synchronizer.start()

func apply_impulse(impulse: Vector2):
	if body:
		body.apply_impulse(impulse)
