class_name PlayerManager
extends Node2D

# 角色列表 { peer_id : Node }
var _avatars: Dictionary[int, UnitEntity] = {}

# Spawner
var _spawner: MultiplayerSpawner

func _ready() -> void:
	# 1. DI 註冊
	DI.register("_player_manager", self)

func _game_start():
	# 2. 設定 Spawner (程式碼動態建立，確保正確性)
	# 如果場景中已經拉了 Spawner 也可以直接用 get_node
	_spawner = MultiplayerSpawner.new()
	_spawner.name = "PlayerSpawner"
	_spawner.spawn_path = "." # 生成在 PlayerManager 底下
	_spawner.spawn_limit = 10
	
	# 設定生成函數 (Server 決定資料 -> Client 同步生成)
	_spawner.spawn_function = _spawn_player_node
	# 監聽生成事件，由 Manager 負責幫新角色注入依賴 (IoC)
	_spawner.spawned.connect(_on_player_spawned)
	add_child(_spawner)
	
	# 3. 監聽登入/登出 (無論 Server/Client 都監聽，避免因啟動順序導致 Miss)
	if not AuthManager.player_logged_in.is_connected(_on_player_logged_in):
		AuthManager.player_logged_in.connect(_on_player_logged_in)
	if not AuthManager.player_logged_out.is_connected(_on_player_logged_out):
		AuthManager.player_logged_out.connect(_on_player_logged_out)
		
	# 補抓已經登入的玩家 (Race Condition Fix)
	for session in AuthManager._sessions.values():
		_on_player_logged_in(session.peer_id, session)

func _on_player_logged_in(peer_id: int, session: AuthManager.Session) -> void:
	print("[PlayerManager] 收到登入事件: ", session.display_name)
	var session_data = {
		"display_name": session.display_name,
		"user_id": session.user_id,
		"role": session.role
	}
	spawn_character(peer_id, session_data)

func _on_player_logged_out(peer_id: int) -> void:
	print("[PlayerManager] 玩家登出，移除角色: ", peer_id)
	if _avatars.has(peer_id):
		var node = _avatars[peer_id]
		if is_instance_valid(node):
			node.queue_free()
		_avatars.erase(peer_id)

# ==============================================================================
# Public API
# ==============================================================================

## [Server Only] 為某個 Peer 生成角色
func spawn_character(peer_id: int, session_data: Dictionary) -> void:
	if not multiplayer.is_server():
		printerr("錯誤: 只有 Server 可以呼叫 spawn_character")
		return
		
	# 呼叫 Spawner 生成 (這會觸發所有 Client 的 _spawn_player_node)
	var spawn_data = {
		"peer_id": peer_id,
		"pos": Vector2(0, 0), # 暫時預設原點，未來可讀取 SpawnPoint
		"name": session_data.get("display_name", "Unknown")
	}
	
	var node = _spawner.spawn(spawn_data)
	if node:
		print("已生成角色: ", node.name)

## 取得特定玩家的角色節點
func get_player_node(peer_id: int) -> UnitEntity:
	return _avatars.get(peer_id)

## [Convenience] 取得本地玩家自己的角色節點
func get_local_player_node() -> UnitEntity:
	return get_player_node(multiplayer.get_unique_id())

## 取得所有角色節點 (供敵人 AI 查詢)
func get_all_avatars() -> Array:
	return _avatars.values()

# ==============================================================================
# Internal (Spawner Callback)
# ==============================================================================

## 真正的生成邏輯 (Server & Client 都會執行)
## data 來自 Server 傳遞的參數
func _spawn_player_node(data: Dictionary) -> Node:
	var peer_id = data.get("peer_id")
	var pos = data.get("pos", Vector2.ZERO)
	
	print("正在生成玩家實體: Peer %d" % peer_id)
	
	# 使用 UnitDB 工廠創建玩家
	var player_instance = UnitDB.create_player(peer_id)
	player_instance.position = pos
	
	# 記錄起來
	_avatars[peer_id] = player_instance
	
	# 監聽物件銷毀 (玩家死亡或斷線)
	player_instance.tree_exiting.connect(func(): _avatars.erase(peer_id))
	
	return player_instance

func _on_player_spawned(node: Node) -> void:
	print("[PlayerManager] 用戶端角色生成，執行 DI 注入: ", node.name)
	DI.injection(node, true)
