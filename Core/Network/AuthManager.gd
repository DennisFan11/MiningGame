extends Node

## AuthManager
## 負責身分驗證、Session 管理以及權限控制 (Kick/Ban)。
## 不負責管理遊戲實體 (Avatar)。

signal player_logged_in(peer_id, session)
signal player_logged_out(peer_id)

# 權限等級
enum ROLE { USER = 0, ADMIN = 99 }

# Session 資料結構
class Session:
	var peer_id: int
	var user_id: String
	var display_name: String
	var role: int = ROLE.USER
	var connect_time: int
	
	func _init(_pid, _uid, _name, _role = ROLE.USER):
		peer_id = _pid
		user_id = _uid
		display_name = _name
		role = _role
		connect_time = Time.get_ticks_msec()

# Active Sessions: { peer_id: Session }
var _sessions: Dictionary = {}

# Ban List (應該存檔，這裡先用暫存)
# { user_id: reason }
var _banned_users: Dictionary = {}

func _ready() -> void:
	# 監聽最底層的連線斷開
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

# ==============================================================================
# Public API
# ==============================================================================

## Client 請求登入
func login(user_id: String, user_name: String) -> void:
	# Client 端呼叫，發送 RPC 給 Server
	_rpc_login.rpc_id(1, user_id, user_name)

## 取得玩家 Session
func get_session(peer_id: int) -> Session:
	return _sessions.get(peer_id)

## 檢查是否為管理員
func is_admin(peer_id: int) -> bool:
	var s = get_session(peer_id)
	return s != null and s.role == ROLE.ADMIN

## [Server Only] 踢人
func kick_peer(peer_id: int, reason: String = "Kicked") -> void:
	if not multiplayer.is_server(): return
	
	print("Kicking peer %d: %s" % [peer_id, reason])
	# 通知該玩家他被踢了 (Optional)
	_rpc_kicked.rpc_id(peer_id, reason)
	
	# 強制斷線
	multiplayer.multiplayer_peer.disconnect_peer(peer_id)

## [Server Only] 封禁
func ban_user(peer_id: int, reason: String = "Banned") -> void:
	if not multiplayer.is_server(): return
	
	var s = get_session(peer_id)
	if s:
		_banned_users[s.user_id] = reason
		kick_peer(peer_id, "Banned: " + reason)

# ==============================================================================
# PRC
# ==============================================================================

@rpc("any_peer", "call_local", "reliable")
func _rpc_login(user_id: String, user_name: String):
	# 只有 Server 處理登入
	if not multiplayer.is_server(): return
	
	var peer_id = multiplayer.get_remote_sender_id()
	print("收到登入請求: Peer %d, User %s (%s)" % [peer_id, user_name, user_id])
	
	# 1. 檢查是否被 Ban
	if _banned_users.has(user_id):
		kick_peer(peer_id, "You are banned: " + _banned_users[user_id])
		return
		
	# 2. 建立 Session
	var role = ROLE.USER
	if peer_id == 1: role = ROLE.ADMIN # Host 預設是管理員
	
	var session = Session.new(peer_id, user_id, user_name, role)
	_sessions[peer_id] = session
	
	# 3. 回覆 Client 登入成功
	_rpc_login_success.rpc_id(peer_id, user_id, user_name, role)
	
	# 4. 觸發信號通知其他系統 (如 GameController)
	player_logged_in.emit(peer_id, session)

@rpc("authority", "call_local", "reliable")
func _rpc_login_success(my_uid: String, my_name: String, my_role: int):
	print("登入成功! 我是: %s (Role: %d)" % [my_name, my_role])
	# Client 端也可以在這裡建立本地的 Session 副本，如果需要的話

@rpc("authority", "call_local", "reliable")
func _rpc_kicked(reason: String):
	print("被踢出伺服器: " + reason)
	NetworkManager.close_connection()
	# TODO: 跳出 UI 顯示原因

# ==============================================================================
# Events
# ==============================================================================

func _on_peer_disconnected(id: int):
	if _sessions.has(id):
		print("Session 清除: Peer ", id)
		_sessions.erase(id)
		player_logged_out.emit(id)
