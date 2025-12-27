class_name BodyComponent
extends Component

var body: CharacterBody2D
var _bitmask_manager: BitmaskManager
var _shape: Shape2D
var _synchronizer: MultiplayerSynchronizer

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
		body.collision_layer = 0
		body.collision_mask = _bitmask_manager.get_wall_layer(BitmaskManager.TEAM.IDLE)
	
	# Create collision shape from data
	if _shape:
		var collider = CollisionShape2D.new()
		collider.shape = _shape
		body.add_child(collider)
	
	# Setup Multiplayer Synchronizer (Server Authority)
	_setup_multiplayer_sync()

func _setup_multiplayer_sync():
	_synchronizer = MultiplayerSynchronizer.new()
	_synchronizer.name = "Synchronizer"
	_synchronizer.set_multiplayer_authority(1) # Server Authority
	
	# 配置同步屬性
	var config = SceneReplicationConfig.new()
	config.add_property(NodePath(".:position"))
	config.add_property(NodePath(".:velocity"))
	
	_synchronizer.replication_config = config
	body.add_child(_synchronizer)
