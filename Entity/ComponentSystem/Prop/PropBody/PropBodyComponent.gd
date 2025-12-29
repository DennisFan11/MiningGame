class_name PropBodyComponent
extends Component

# 內部變數 (Strict Naming: _property)
var _shape: Shape2D
var _mass: float = 1.0

var body: RigidBody2D
var _synchronizer: NetworkSynchronizer

func _on_data_set(data: ComponentData):
	if data is PropBodyComponentData:
		_shape = data.shape
		_mass = data.mass

var _bitmask_manager: BitmaskManager

# Injected State
var __prop_state: PropState

func _ready() -> void:
	# 建立物理實體
	body = RigidBody2D.new()
	body.name = "Body"
	body.mass = _mass
	body.gravity_scale = 0.0
	
	body.linear_damp_mode = RigidBody2D.DAMP_MODE_COMBINE
	body.linear_damp = 10.0
	
	body.physics_material_override = PhysicsMaterial.new()
	body.physics_material_override.bounce = 1.0
	
	# Layer 32 (Prop)
	var prop_layer = _bitmask_manager.get_prop_layer()
	body.collision_layer = prop_layer
	body.collision_mask = prop_layer | _bitmask_manager.get_wall_layer()
	body.collision_mask |= _bitmask_manager.PLAYER_LAYER
	#body.collision_layer |= _bitmask_manager.PLAYER_LAYER
	add_child(body)
	

func _on_setuped():
	if _shape:
		var collider = CollisionShape2D.new()
		collider.shape = _shape
		body.add_child(collider)
	
	_setup_multiplayer_sync()
	
	# Check State via Injection
	if __prop_state:
		# World State: Dynamic Mode
		body.freeze = false
		
		# Set Initial Position (Global) directly to Body
		# Root Entity stays at spawn point (0,0 relative to parent or whatever)
		# Body moves independently via physics
		body.global_position = __prop_state.position
		
		if __prop_state.force != Vector2.ZERO:
			body.apply_central_impulse(__prop_state.force)

# Note: _physics_process removed as we no longer sync Entity to Body

func _setup_multiplayer_sync():
	_synchronizer = NetworkSynchronizer.new()
	_synchronizer.name = "Synchronizer"
	_synchronizer.set_multiplayer_authority(1)
	
	_synchronizer.add_property(NodePath("Body:position"), true)
	_synchronizer.add_property(NodePath("Body:rotation"), true)
	_synchronizer.add_property(NodePath("Body:linear_velocity"), false) # Velocity usually doesn't need smooth visual interp if Position is handled, or it fights physics. Keep generic for now.
	_synchronizer.add_property(NodePath("Body:angular_velocity"), false)
	
	add_child(_synchronizer)
	
	if not multiplayer.is_server():
		_synchronizer.start()

func apply_impulse(impulse: Vector2):
	if body:
		body.apply_impulse(impulse)
