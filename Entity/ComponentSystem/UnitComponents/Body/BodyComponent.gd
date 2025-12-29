class_name BodyComponent
extends Component

var body: CharacterBody2D
var _bitmask_manager: BitmaskManager
var _shape: Shape2D
var _synchronizer: NetworkSynchronizer

func _on_data_set(data: ComponentData):
	if data is BodyComponentData:
		_shape = data.shape
	
	# create body directly
	body = CharacterBody2D.new()
	body.name = "Body"
	add_child(body)

func _on_setuped():
	# Setup collision - only with walls
	if _bitmask_manager:
		body.collision_layer = _bitmask_manager.PLAYER_LAYER
		body.collision_mask = _bitmask_manager.get_wall_layer(BitmaskManager.TEAM.IDLE)
	
	# Create collision shape from data
	if _shape:
		var collider = CollisionShape2D.new()
		collider.shape = _shape
		body.add_child(collider)
	
	# Setup Multiplayer Synchronizer (Server Authority)
	_setup_multiplayer_sync()

func _setup_multiplayer_sync():
	_synchronizer = NetworkSynchronizer.new()
	_synchronizer.name = "Synchronizer"
	_synchronizer.set_multiplayer_authority(1) # Server Authority
	_synchronizer.sync_every_frame = true
	
	# 配置同步屬性
	_synchronizer.add_property(NodePath(".:position"), true)
	_synchronizer.add_property(NodePath(".:velocity"), true)
	
	body.add_child(_synchronizer)
	
	if not multiplayer.is_server():
		_synchronizer.start()
