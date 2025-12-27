class_name PropBodyComponent
extends Component

# 內部變數 (Strict Naming: _property)
var _shape: Shape2D
var _mass: float = 1.0

var body: RigidBody2D
var _synchronizer: MultiplayerSynchronizer

func _on_data_set(data: ComponentData):
	if data is PropBodyComponentData:
		_shape = data.shape
		_mass = data.mass

# Injected State
var __prop_state: PropState

func _on_setuped():
	# 建立物理實體
	body = RigidBody2D.new()
	body.name = "Body"
	body.mass = _mass
	body.gravity_scale = 0.0
	
	# Layer 32 (Prop)
	var prop_layer = 1 << 5
	body.collision_layer = prop_layer
	body.collision_mask = 1 | prop_layer
	
	add_child(body)
	
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
	_synchronizer = MultiplayerSynchronizer.new()
	_synchronizer.name = "Synchronizer"
	_synchronizer.set_multiplayer_authority(1)
	
	var config = SceneReplicationConfig.new()
	config.add_property(NodePath("Body:position"))
	config.add_property(NodePath("Body:rotation"))
	config.add_property(NodePath("Body:linear_velocity"))
	config.add_property(NodePath("Body:angular_velocity"))
	
	_synchronizer.replication_config = config
	add_child(_synchronizer)

func apply_impulse(impulse: Vector2):
	if body:
		body.apply_impulse(impulse)
