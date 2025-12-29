class_name NetworkSpawner
extends Node

## NetworkSpawner
## 一個獨立的節點，用於經由 RPC 生成和管理網路實體。
## 旨在取代 Godot 原生的 MultiplayerSpawner，解決 Late Join Race Condition 問題。
##
## 特性:
## 1. 獨立運作：不依賴 NetworkManager，自行處理連線訊號。
## 2. Late Join 支援：自動處理新連線玩家的物件同步。
## 3. 魯棒性：具備冪等性檢查、防呆機制。

# 配置
@export var spawn_path: NodePath:
	set(value):
		spawn_path = value
		_update_watcher()

var spawn_function: Callable

# 狀態跟踪
# Server: { node_name: data }
# Client: { node_name: null } (主要用於驗證是否為受控節點)
var _spawned_nodes: Dictionary = {}

# Client Only: 追蹤合法的移除請求，用於防呆檢查
var _authorized_despawns: Dictionary = {}

var _current_watched_node: Node

func _enter_tree() -> void:
	# Server 和 Client 都需要監聽，以確保狀態一致性並進行防呆
	_update_watcher()

func _ready() -> void:
	# 僅伺服器需要監聽連線以進行同步
	# Client 端改由 start() 手動觸發同步，配合 _game_start 流程
	pass

# ==============================================================================
# Public API (Common)
# ==============================================================================

## 啟動同步
## 應在 Client 端確認場景/依賴載入完成後呼叫 (例如 _game_start)
func start():
	if not multiplayer.is_server():
		# 延遲一幀確保連線狀態穩定
		await get_tree().process_frame
		if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			_request_sync.rpc_id(1)

# ==============================================================================
# Public API (Server Only)
# ==============================================================================

## 生成物件
## @param data: 傳遞給 spawn_function 的資料字典。必須包含足夠重建節點的資訊。
## @return: 生成的節點實體，如果生成失敗則返回 null。
func spawn(data: Dictionary) -> Node:
	if not multiplayer.is_server():
		push_error("NetworkSpawner: spawn called on client.")
		return null
		
	# 檢查必要參數
	if not spawn_function.is_valid():
		push_error("NetworkSpawner: spawn_function is not valid.")
		return null
		
	# 執行生成
	var node = spawn_function.call(data)
	
	# 檢查生成結果
	if not is_instance_valid(node):
		push_error("NetworkSpawner: spawn_function returned invalid node.")
		return null
		
	if not node is Node:
		push_error("NetworkSpawner: spawn_function must return a Node.")
		node.free()
		return null
		
	# 設定並確保名稱唯一
	# 如果 spawn_function 沒設定名稱，我們需要給一個
	# 通常建議 data 裡包含 id 或 unique key
	if node.name.is_empty() or node.name.begins_with("@"):
		node.name = "NetNode_" + str(randi())
		
	var node_name = node.name
	
	# 加入場景樹
	var parent = get_node_or_null(spawn_path)
	if not parent:
		push_error("NetworkSpawner: spawn_path is invalid: " + str(spawn_path))
		node.free()
		return null
		
	parent.add_child(node)
	
	# 記錄狀態
	_spawned_nodes[node_name] = data
	
	# 廣播給所有客戶端
	_rpc_spawn.rpc(node_name, data)
	
	return node

## 移除物件
## @param node: 要移除的節點實體
func despawn(node: Node) -> void:
	if not multiplayer.is_server():
		push_error("NetworkSpawner: despawn called on client.")
		return
		
	if not is_instance_valid(node):
		return
		
	var node_name = node.name
	
	# 檢查是否為受控節點
	if not _spawned_nodes.has(node_name):
		push_warning("NetworkSpawner: Try to despawn a node not managed by this spawner: " + node_name)
		return

	# 移除狀態
	_spawned_nodes.erase(node_name)
	
	# 廣播移除
	_rpc_despawn.rpc(node_name)
	
	# 執行刪除
	# 注意：queue_free 會觸發 child_exiting_tree，
	# 但因為我們已經從 _spawned_nodes 移除了，所以 callback 會安全忽略。
	node.queue_free()

func _update_watcher():
	if not is_inside_tree():
		return
		
	if _current_watched_node and is_instance_valid(_current_watched_node):
		if _current_watched_node.child_exiting_tree.is_connected(_on_child_exiting_tree):
			_current_watched_node.child_exiting_tree.disconnect(_on_child_exiting_tree)
	
	_current_watched_node = null
	
	if spawn_path.is_empty():
		return
		
	var node = get_node_or_null(spawn_path)
	if node:
		node.child_exiting_tree.connect(_on_child_exiting_tree)
		_current_watched_node = node

func _on_child_exiting_tree(node: Node):
	# 當受控節點被移除（無論是透過 despawn 還是外部 queue_free）
	# 我們都要確保同步給客戶端
	var node_name = node.name
	
	if multiplayer.is_server():
		# Server Logic: Sync to Clients
		if _spawned_nodes.has(node_name):
			_spawned_nodes.erase(node_name)
			_rpc_despawn.rpc(node_name)
	else:
		# Client Logic: Illegal Deletion Guard
		if _spawned_nodes.has(node_name):
			# 檢查是否為 authorized despawn
			if _authorized_despawns.has(node_name):
				# 合法移除，清除標記
				_authorized_despawns.erase(node_name)
				_spawned_nodes.erase(node_name)
			else:
				# 非法移除！ (Client 自作主張 queue_free)
				push_error("NetworkSpawner [Client]: 非法移除受控節點 (%s)！正在重新同步..." % node_name)
				# 重新同步：Client 主動跟 Server 要資料，把消失的節點補回來
				start()

# ==============================================================================
# Internal / Callbacks
# ==============================================================================

## 處理新玩家同步請求
## 由 Client 端在 _ready 時呼叫
@rpc("any_peer", "call_remote", "reliable")
func _request_sync():
	if not multiplayer.is_server(): return
	
	var peer_id = multiplayer.get_remote_sender_id()
	# print("NetworkSpawner: Sending sync data to peer ", peer_id)
	
	for node_name in _spawned_nodes:
		var data = _spawned_nodes[node_name]
		_rpc_spawn.rpc_id(peer_id, node_name, data)

# ==============================================================================
# RPCs
# ==============================================================================

@rpc("authority", "call_remote", "reliable")
func _rpc_spawn(node_name: String, data: Dictionary) -> void:
	# [魯棒性] 檢查 Parent
	var parent = get_node_or_null(spawn_path)
	if not parent:
		push_error("NetworkSpawner [Client]: Invalid spawn_path: " + str(spawn_path))
		return
		
	# [魯棒性 - 冪等性] 檢查是否已存在
	if parent.has_node(node_name):
		# 如果節點已存在，我們仍需確保它被註冊在 _spawned_nodes 中
		# 這確保了後續刪除檢查的正確性
		if not _spawned_nodes.has(node_name):
			_spawned_nodes[node_name] = data
		return
		
	# [魯棒性] 檢查 spawn_function
	if not spawn_function.is_valid():
		push_error("NetworkSpawner [Client]: spawn_function is not valid.")
		return

	# 執行生成
	var node = spawn_function.call(data)
	
	if not is_instance_valid(node):
		push_error("NetworkSpawner [Client]: spawn_function failed.")
		return

	# 強制設定名稱以同步
	node.name = node_name
	
	# 加入場景
	parent.add_child(node)
	
	# Client 端註冊
	_spawned_nodes[node_name] = data

@rpc("authority", "call_remote", "reliable")
func _rpc_despawn(node_name: String) -> void:
	var parent = get_node_or_null(spawn_path)
	if not parent:
		return
		
	# 標記為合法移除 (使用 Dictionary 當 Set 用)
	_authorized_despawns[node_name] = true
		
	# [魯棒性] 檢查節點是否存在
	var node = parent.get_node_or_null(node_name)
	if node:
		node.queue_free()
	else:
		# 節點已消失，移除標記以免殘留
		_authorized_despawns.erase(node_name)
