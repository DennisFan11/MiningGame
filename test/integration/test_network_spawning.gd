extends GutTest

# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------

var server_root: Node
var client_root: Node
var server_peer: ENetMultiplayerPeer
var client_peer: ENetMultiplayerPeer

var server_spawner: NetworkSpawner
var client_spawner: NetworkSpawner

var server_container: Node
var client_container: Node

func before_each():
    await _setup_network()

func after_each():
    _teardown_network()

func _setup_network():
    # 1. 建立根節點
    server_root = Node.new()
    server_root.name = "ServerRoot"
    add_child(server_root)
    
    client_root = Node.new()
    client_root.name = "ClientRoot"
    add_child(client_root)

    # 2. 建立容器 (Spawn Container)
    server_container = Node.new()
    server_container.name = "SpawnContainer"
    server_root.add_child(server_container)
    
    client_container = Node.new()
    client_container.name = "SpawnContainer"
    client_root.add_child(client_container)

    # 3. 建立 NetworkSpawner
    server_spawner = NetworkSpawner.new()
    server_spawner.name = "TestSpawner"
    server_spawner.spawn_path = server_container.get_path()
    server_spawner.spawn_function = _simple_spawn_func
    server_root.add_child(server_spawner) # 放在 Root 下，與 Container 平行
    
    client_spawner = NetworkSpawner.new()
    client_spawner.name = "TestSpawner"
    client_spawner.spawn_path = client_container.get_path()
    client_spawner.spawn_function = _simple_spawn_func
    client_root.add_child(client_spawner)

    # 4. 配置 MultiplayerAPI
    server_peer = ENetMultiplayerPeer.new()
    var err = server_peer.create_server(0)
    if err != OK:
        push_error("Failed to create server")
        return
    var port = server_peer.host.get_local_port()
    
    var server_api = SceneMultiplayer.new()
    server_api.root_path = server_root.get_path()
    get_tree().set_multiplayer(server_api, server_root.get_path())
    server_api.multiplayer_peer = server_peer
    
    client_peer = ENetMultiplayerPeer.new()
    client_peer.create_client("127.0.0.1", port)
    
    var client_api = SceneMultiplayer.new()
    client_api.root_path = client_root.get_path()
    get_tree().set_multiplayer(client_api, client_root.get_path())
    client_api.multiplayer_peer = client_peer

    # 等待連線
    var waited = 0.0
    while waited < 2.0:
        if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
            break
        await wait_seconds(0.5)
        waited += 0.5
        
    if client_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
        push_error("Client failed to connect in setup")
        
    # Wait for Server to acknowledge peer
    waited = 0.0
    while waited < 2.0:
        if server_root.multiplayer.get_peers().size() > 0:
            break
        await wait_seconds(0.1)
        waited += 0.1
        
    if server_root.multiplayer.get_peers().size() == 0:
        push_error("Server failed to acknowledge client")

func _teardown_network():
    if is_instance_valid(server_peer): server_peer.close()
    if is_instance_valid(client_peer): client_peer.close()
    if is_instance_valid(server_root): server_root.free()
    if is_instance_valid(client_root): client_root.free()

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

# 簡單的生成函數
func _simple_spawn_func(data: Dictionary) -> Node:
    var node = Node2D.new()
    node.name = data.get("name", "Node")
    
    # 設置一些屬性以驗證數據傳遞
    if data.has("pos"):
        node.position = data["pos"]
        
    return node

# ------------------------------------------------------------------------------
# Test Cases
# ------------------------------------------------------------------------------

# [目的] 測試基本的生成同步 (Server -> Client)
func test_simple_spawn_sync():
    # Client 啟動同步
    client_spawner.start()
    
    # Server 生成物件
    var data = {"name": "TestNode_01", "pos": Vector2(100, 200)}
    server_spawner.spawn(data)
    
    await wait_seconds(0.5)
    
    # 驗證
    assert_eq(client_container.get_child_count(), 1, "Client 應收到 1 個節點")
    var client_node = client_container.get_node_or_null("TestNode_01")
    assert_not_null(client_node, "Client 應有 TestNode_01")
    if client_node:
        assert_eq(client_node.position, Vector2(100, 200), "屬性 (Position) 應同步")

# [目的] 測試移除同步 (Despawn)
func test_despawn_sync():
    client_spawner.start()
    
    # Setup: 先生成一個
    var data = {"name": "NodeToKill"}
    var node = server_spawner.spawn(data)
    
    await wait_seconds(0.2)
    assert_eq(client_container.get_child_count(), 1)
    
    # Action: Server 移除
    server_spawner.despawn(node)
    
    await wait_seconds(0.5)
    
    # Verify
    assert_eq(client_container.get_child_count(), 0, "Client 節點應被移除")

# [目的] 測試 Late Join (後加入的玩家能收到之前的物件)
func test_late_join_sync():
    # 1. 斷開 Client (模擬尚未連線)
    client_peer.close()
    # 確保 server 端也知道 client 斷了 (雖然這裡是 spawn server-side unrelated to client presence)
    
    # 2. Server 生成物件
    server_spawner.spawn({"name": "ExistingNode_A", "pos": Vector2(50, 50)})
    server_spawner.spawn({"name": "ExistingNode_B", "pos": Vector2(100, 100)})
    
    await wait_seconds(0.2)
    
    # 3. Client 連線 (New Player)
    client_peer = ENetMultiplayerPeer.new()
    client_peer.create_client("127.0.0.1", server_peer.host.get_local_port())
    client_root.get_multiplayer().multiplayer_peer = client_peer
    
    # 等待連線建立
    await wait_seconds(0.5)
    
    # 4. Client 啟動同步 (Start)
    client_spawner.start()
    
    await wait_seconds(0.5)
    
    # Verify
    assert_eq(client_container.get_child_count(), 2, "Late Join Client 應收到所有現存物件")
    assert_not_null(client_container.get_node_or_null("ExistingNode_A"))
    assert_not_null(client_container.get_node_or_null("ExistingNode_B"))

# [目的] 測試重名處理 (Robustness)
# 如果生成兩個相同名字的節點 (理論上 spawn_function 應該避免，但測試 spawner 是否能處理)
func test_duplicate_name_handling():
    client_spawner.start()
    
    var data1 = {"name": "SameName"}
    server_spawner.spawn(data1)
    
    var data2 = {"name": "SameName"} # Intentional duplicate
    server_spawner.spawn(data2)
    
    await wait_seconds(0.5)
    
    # Godot 會自動命名为 SameName2, SameName3 等
    # NetworkSpawner 應該廣播最終確定的名字
    
    assert_eq(client_container.get_child_count(), 2, "Client 應收到 2 個節點")
    
    var c1 = client_container.get_child(0)
    var c2 = client_container.get_child(1)
    
    assert_ne(c1.name, c2.name, "節點名稱應不相同")
    # 確認兩邊一致 (這需要更深入檢查 internal map，或是檢查 name 是否對應)
    # 這裡只檢查 Client 有收到兩個東西即可
