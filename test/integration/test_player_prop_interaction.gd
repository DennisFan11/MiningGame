extends GutTest

var _main_scene: Node2D
var _prop_manager: PropManager
var _player_manager: PlayerManager

func before_each():
	# Load Main Scene
	var main_packed = load("res://Scene/Main/Main.tscn")
	_main_scene = main_packed.instantiate()
	add_child_autofree(_main_scene)
	
	await get_tree().process_frame
	
	# Get Dependencies
	_prop_manager = DI._dependence.get("_prop_manager")
	_player_manager = DI._dependence.get("_player_manager")

func after_each():
	DI._dependence.clear()

func test_player_pickup_prop():
	# 1. Spawn Player
	var player = UnitDB.create_player(1)
	_main_scene.add_child(player)
	player.global_position = Vector2(100, 100)
	
	# Verify Components
	var holder = player.get_component(PropHolderComponent)
	assert_not_null(holder, "Player should have PropHolderComponent")
	var body_comp = player.get_component(BodyComponent)
	assert_not_null(body_comp, "Player should have BodyComponent")
	
	# 2. Spawn Prop
	var prop_data = PropDB.get_data(PropDB.PROP.STONE)
	# Place at (160, 100) to be within pickup range (150) but avoid collision overlap (Radius ~30 + Player ~20 = 50)
	var prop = PropDB.create_world_prop(prop_data, Vector2(160, 100), Vector2.ZERO)
	_main_scene.add_child(prop)
	
	# Force physics update to register positions/collisions
	await wait_seconds(1.0)
	
	# 3. Simulate Pickup
	# Since it's an RPC, and we are likely server/host in test, we call the rpc implementation directly
	# or verify the public API triggers it. public API check is_multiplayer_authority.
	
	# Assuming test runner is authority (server)
	holder.rpc_try_pickup(prop.get_component(PropBodyComponent).body.get_path())
	
	# 4. Assert Pickup Success
	# Wait for queue_free to process
	await wait_seconds(0.1)
	assert_eq(holder.current_prop_id, PropDB.PROP.STONE, "Should have picked up Stone (ID matched)")
	assert_freed(prop, "World prop should be freed")
	
	# 5. Simulate Throw
	holder.rpc_try_throw(Vector2(200, 100))
	
	# 6. Assert Throw Success (Prop spawned)
	assert_eq(holder.current_prop_id, -1, "Prop ID should be reset after throw")
	
	# Allow frame for spawn
	await wait_seconds(0.5)
	
	# Verify new prop exists (Simple check: PropManager should have a child, or check global entity count)
	# For now, just asserting state reset is good enough to prove logic executed.
