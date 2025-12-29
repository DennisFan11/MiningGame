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
@export var spawn_path: NodePath
var spawn_function: Callable

# 狀態跟踪 (Server Only)
# { node_name: spawn_data }
var _spawned_nodes: Dictionary = {}

func _ready() -> void:
	# 僅伺服器需要監聽連線以進行同步
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)

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
		
	# [魯棒性] 檢查必要參數
	if not spawn_function.is_valid():
		push_error("NetworkSpawner: spawn_function is not valid.")
		return null
		
	# 執行生成
	var node = spawn_function.call(data)
	
	# [魯棒性] 檢查生成結果
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
	
	# [魯棒性] 檢查是否為受控節點
	if not _spawned_nodes.has(node_name):
		push_warning("NetworkSpawner: Try to despawn a node not managed by this spawner: " + node_name)
		# 雖然不是我們生成的，但如果呼叫者執意要刪，我們還是可以幫忙刪，
		# 但為了安全起見，這裡只處理受控節點。
		# 若要刪除非受控節點，應直接 queue_free 或用其他邏輯。
		return

	# 移除狀態
	_spawned_nodes.erase(node_name)
	
	# 廣播移除
	_rpc_despawn.rpc(node_name)
	
	# 執行刪除
	node.queue_free()

# ==============================================================================
# Internal / Callbacks
# ==============================================================================

## 處理新玩家連線 (Late Join Sync)
func _on_peer_connected(peer_id: int):
	# 將當前所有存活的節點同步給新玩家
	# 使用 loop 發送多個 RPC
	# 為了避免瞬間流量過大，未來可考慮分批發送，目前先直接送
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
		# 節點已存在，視為已同步
		# 這情況發生在 Late Join 同步封包 與 即時生成廣播 同時到達時
		# print_verbose("NetworkSpawner [Client]: Node already exists, skipping spawn: ", node_name)
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

@rpc("authority", "call_remote", "reliable")
func _rpc_despawn(node_name: String) -> void:
	var parent = get_node_or_null(spawn_path)
	if not parent:
		return
		
	# [魯棒性] 檢查節點是否存在
	var node = parent.get_node_or_null(node_name)
	if node:
		node.queue_free()
	else:
		# 節點不存在可能是因為已經被刪除了，或是這是一個重複的 despawn 封包
		# 安全忽略
		pass
