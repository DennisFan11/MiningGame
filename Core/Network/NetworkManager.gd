extends Node

## NetworkManager
## 負責管理連線生命週期、玩家連線事件處理、以及場景切換。

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const PORT = 7000
const DEFAULT_IP = "127.0.0.1"
const MAX_CLIENTS = 4

## 玩家列表格式: { peer_id: { "name": "PlayerName", "id": peer_id } }
var players: Dictionary = {}

## 玩家資訊 (本地)
var player_info = {"name": "Player"}

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# ==============================================================================
# Public API
# ==============================================================================

## 啟動主機 (Host)
func start_host(is_single_player: bool = false) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 1 if is_single_player else MAX_CLIENTS)
	
	if is_single_player:
		# 單人模式僅允許本地連線，稍微優化頻寬 (雖然本地回環沒差)
		peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	if error != OK:
		printerr("無法啟動 Host: " + str(error))
		return
		
	multiplayer.multiplayer_peer = peer
	print("Host 已啟動 (單人模式: %s)" % is_single_player)
	
	# Host 自己也是玩家，手動觸發連線邏輯
	_on_peer_connected(1)
	
	# 載入遊戲場景
	_load_game_scene()

## 加入遊戲 (Client)
func join_game(address: String = "") -> void:
	if address.is_empty():
		address = DEFAULT_IP
		
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	
	if error != OK:
		printerr("無法建立 Client: " + str(error))
		return
		
	multiplayer.multiplayer_peer = peer
	print("正在連線至 %s..." % address)

## 斷開連線
func close_connection() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()
	# 回到主選單 (尚未實作，暫時 reload)
	# get_tree().change_scene_to_file("res://Scene/Menu/MainMenu.tscn") 

# ==============================================================================
# Internal Logic
# ==============================================================================

## 載入遊戲主場景
func _load_game_scene():
	# 這裡假設 Main.tscn 是我們的遊戲主場景
	# 在實際專案中可能需要先切換到 Loading 畫面
	get_tree().change_scene_to_file("res://Scene/Main/Main.tscn")

## 註冊玩家
func _register_player(id: int, info: Dictionary):
	players[id] = info
	player_connected.emit(id, info)
	print("玩家已註冊: %s (ID: %d)" % [info.name, id])

# ==============================================================================
# Signals Callbacks
# ==============================================================================

func _on_peer_connected(id: int):
	print("Peer 連線: ", id)
	# 這裡可以實作握手協議 (Handshake) 來交換玩家名稱
	# 目前簡化為直接註冊
	_register_player(id, {"name": "Player_" + str(id), "id": id})

func _on_peer_disconnected(id: int):
	print("Peer 斷線: ", id)
	if players.has(id):
		players.erase(id)
	player_disconnected.emit(id)

func _on_connected_ok():
	print("成功連線至伺服器!")
	
	# [新增] 自動登入流程
	var my_name = player_info.get("name", "Unknown")
	var my_uid = str(randi()) # 暫時使用隨機 ID，未來可接 SteamID
	AuthManager.login(my_uid, my_name)

func _on_connected_fail():
	printerr("連線失敗!")
	close_connection()

func _on_server_disconnected():
	print("與伺服器斷開連線")
	server_disconnected.emit()
	close_connection()
