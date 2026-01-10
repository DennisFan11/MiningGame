extends GutTest

# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------

var server_root: Node
var client_root: Node
var server_peer: ENetMultiplayerPeer
var client_peer: ENetMultiplayerPeer

var server_syncer: NetworkSynchronizer
var client_syncer: NetworkSynchronizer

var server_target: Node2D
var client_target: Node2D

## 測試前置設置，建立基本網路環境與節點
func before_each():
	await _setup_network()

## 測試後清理，釋放資源
func after_each():
	_teardown_network()

## 建立 Server 與 Client 的網路連接及測試物件
func _setup_network():
	# 1. Roots (Must be in tree to have path)
	server_root = Node.new(); server_root.name = "ServerRoot"; add_child(server_root)
	client_root = Node.new(); client_root.name = "ClientRoot"; add_child(client_root)

	# 2. Network Configuration (Set API FIRST)
	server_peer = ENetMultiplayerPeer.new(); server_peer.create_server(0)
	var port = server_peer.host.get_local_port()
	var server_api = SceneMultiplayer.new(); server_api.root_path = server_root.get_path()
	get_tree().set_multiplayer(server_api, server_root.get_path()) # Override for this path
	server_api.multiplayer_peer = server_peer

	client_peer = ENetMultiplayerPeer.new(); client_peer.create_client("127.0.0.1", port)
	var client_api = SceneMultiplayer.new(); client_api.root_path = client_root.get_path()
	get_tree().set_multiplayer(client_api, client_root.get_path()) # Override for this path
	client_api.multiplayer_peer = client_peer

	# 3. Target Nodes (Synced Objects) & Synchronizers
	# Now when they enter tree, they will see the correct Custom MultiplayerAPI
	server_target = Node2D.new(); server_target.name = "Target"; server_root.add_child(server_target)
	client_target = Node2D.new(); client_target.name = "Target"; client_root.add_child(client_target)

	server_syncer = NetworkSynchronizer.new()
	server_syncer.name = "NetSync"
	server_syncer.root_path = ".."
	server_target.add_child(server_syncer)
	
	client_syncer = NetworkSynchronizer.new()
	client_syncer.name = "NetSync"
	client_target.add_child(client_syncer)

	# Wait connection
	await wait_for_connection(client_peer)

## 銷毀網路與節點
func _teardown_network():
	if is_instance_valid(server_peer): server_peer.close()
	if is_instance_valid(client_peer): client_peer.close()
	if is_instance_valid(server_root): server_root.free()
	if is_instance_valid(client_root): client_root.free()

## 等待客戶端連線成功
func wait_for_connection(peer):
	var timer = 0.0
	while peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED and timer < 2.0:
		await wait_seconds(0.1)
		timer += 0.1
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		push_error("Failed to connect")

# ------------------------------------------------------------------------------
# Tests
# ------------------------------------------------------------------------------

## 測試基本同步：驗證 Server 端數值變更可正確同步至 Client
func test_initial_sync():
	# Config: Sync Position
	# Use ":position" to indicate property on self (root).
	server_syncer.add_property(NodePath(":position"), false)
	client_syncer.add_property(NodePath(":position"), false)
	
	# Action: Change Server Pos
	server_target.position = Vector2(100, 200)
	
	# Trigger Sync (Wait for timer)
	await wait_seconds(server_syncer.sync_interval + 0.1)
	
	# Assert
	assert_eq(client_target.position, Vector2(100, 200), "Position should be synced")

## 測試插值同步：Client 端開啟插值後，數值應平滑移動至目標
func test_interpolation():
	server_syncer.sync_interval = 0.05
	server_syncer.add_property(NodePath(":position"), false) # Server side config
	client_syncer.add_property(NodePath(":position"), true) # Client enables interpolation
	client_syncer.interpolation_speed = 10.0 # Slow enough to observe
	
	# Initial Sync to (0,0)
	server_target.position = Vector2.ZERO
	await wait_seconds(0.1)
	assert_eq(client_target.position, Vector2.ZERO)
	
	# Move Server
	server_target.position = Vector2(100, 0)
	
	# Wait for update packet
	await wait_seconds(0.1)
	
	# Client should be moving towards (100, 0) but not there yet
	# Only 1 or 2 frames passed since packet arrival? 
	# We need to simulate _process logic. GUT runs _process automatically? Yes if added to tree.
	
	await wait_seconds(0.1)
	
	assert_gt(client_target.position.x, 0.0, "Should have started moving")
	assert_lt(client_target.position.x, 100.0, "Should be interpolating, not instant")
	
	# Wait enough time to finish
	await wait_seconds(1.0)
	assert_almost_eq(client_target.position.x, 100.0, 1.0, "Should eventually reach target")

## 測試強制同步 (Snap)：當數值差距過大時，應忽略插值直接修正位置
func test_snap_margin():
	client_syncer.add_property(NodePath(":position"), true)
	client_syncer.snap_margin = 50.0
	server_syncer.add_property(NodePath(":position"), false)
	
	# 1. Small move (interpolate)
	server_target.position = Vector2(10, 0)
	await wait_seconds(0.1)
	# Should be interpolating (checked in previous test), but let's assume it works.
	
	# 2. Big move (Snap)
	server_target.position = Vector2(1000, 0) # > 50 distance
	await wait_seconds(0.1)
	
	# Should be instant (or very close to it, essentially at target)
	# If interpolating 1000 units with speed 35, it takes seconds.
	# If snapped, it's there instantly.
	
	assert_eq(client_target.position, Vector2(1000, 0), "Should snap immediately efficiently")

## 測試差量壓縮：如果數值未變更，理論上不應導致錯誤更新 (功能驗證)
func test_delta_compression():
	# specific_check_on_change = true by default
	server_syncer.add_property(NodePath(":position"), false)
	client_syncer.add_property(NodePath(":position"), false)
	
	server_target.position = Vector2(50, 50)
	
	# Capture RPC calls? 
	# GUT doesn't easily spy on RPCs unless we mock the function.
	# But we can verify functionally.
	
	await wait_seconds(0.1)
	server_target.position = Vector2(50, 50) # No change
	
	# If we could spy, we would verify no RPC sent. 
	# For now, just ensure it doesn't break anything.
	await wait_seconds(0.1)
	assert_eq(client_target.position, Vector2(50, 50))

## 測試 Late Join：新加入的 Client 應能主動請求並接收當前世界狀態
func test_late_join():
	# 1. Setup Server State
	server_syncer.add_property(NodePath(":position"), false)
	server_target.position = Vector2(123, 456)
	
	# 2. Simulate Late Join Client
	# Instead of freeing (which causes RPC errors if packets arrive mid-transition),
	# we just reset the client state to simulate "Wrong/Fresh" state.
	# The goal is to verify start() fetches the authoritative state.
	
	client_target.position = Vector2.ZERO # Reset state
	
	# Ensure properties are configured (already done in setup, but we added one in step 1?)
	# Setup adds NO properties. 
	# Step 1 added property to server.
	# We must add property to client too (if not done).
	client_syncer.add_property(NodePath(":position"), false)
	
	# 3. Start Sync (Manual Request)
	client_syncer.start()
	
	await wait_seconds(0.2)
	
	# Assert
	assert_eq(client_target.position, Vector2(123, 456), "Late joiner should request and receive sync")
