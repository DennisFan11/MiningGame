class_name MainMenu
extends Node2D

## Main Menu with Dynamic UI Generation
## 負責產生主選單介面並連接 NetworkManager

# UI Components
var _vbox: VBoxContainer
var _ip_input: LineEdit
var _name_input: LineEdit
var _server_list: ItemList

func _ready() -> void:
	_setup_ui()

# ==============================================================================
# Business Logic (Events)
# ==============================================================================

func _on_single_player_pressed() -> void:
	_save_player_info()
	print("啟動單人模式...")
	NetworkManager.start_host(NetworkManager.DEFAULT_PORT, true) # true = single player mode

func _on_host_pressed() -> void:
	_save_player_info()
	print("啟動區域連線主機...")
	NetworkManager.start_host(NetworkManager.DEFAULT_PORT, false) # false = multiplayer mode

func _on_join_pressed() -> void:
	_save_player_info()
	var ip_text = _ip_input.text
	
	# 使用 static function 時建議加上 class name
	var result = NetworkManager.parse_address_string(ip_text)
	
	if not result.valid:
		_show_error("無效的地址格式！")
		return
		
	var ip = result.ip
	var port = result.port
	var protocol = result.protocol
			
	print("嘗試加入伺服器: %s:%d (Protocol: %s)" % [ip, port, "TCP" if protocol == NetworkManager.Protocol.TCP else "UDP"])
	
	NetworkManager.join_game(ip, port, protocol)

# ... (omitted) ...


func _save_player_info() -> void:
	var player_name = _name_input.text
	if player_name.is_empty():
		player_name = "Player_" + str(randi() % 1000)
	
	# 更新 NetworkManager 的資訊
	NetworkManager.player_info["name"] = player_name
	print("設定玩家名稱: ", player_name)

# ==============================================================================
# UI Implementation (Internal)
# ==============================================================================

func _setup_ui() -> void:
	# 尋找或建立 UI 容器
	var canvas_layer = $CanvasLayer
	var control = canvas_layer.get_node("Control")
	
	# 建立垂直排列容器
	_vbox = VBoxContainer.new()
	_vbox.anchor_left = 0.5
	_vbox.anchor_top = 0.5
	_vbox.anchor_right = 0.5
	_vbox.anchor_bottom = 0.5
	_vbox.offset_left = -280
	_vbox.offset_top = -300
	_vbox.offset_right = 280
	_vbox.offset_bottom = 300
	_vbox.add_theme_constant_override("separation", 20)
	control.add_child(_vbox)
	
	# 1. 標題
	var label = Label.new()
	label.text = "Miningame Multiplayer"
	label.add_theme_font_size_override("font_size", 48) # Slightly smaller title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(label)
	
	# 1.5 玩家名稱輸入
	_vbox.add_child(Label.new()) # Spacer
	var name_label = Label.new()
	name_label.text = "Player Name:"
	name_label.add_theme_font_size_override("font_size", 32)
	_vbox.add_child(name_label)
	
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Enter Name"
	_name_input.text = "Player"
	_name_input.custom_minimum_size.y = 50 # Slightly smaller
	_name_input.add_theme_font_size_override("font_size", 28)
	_vbox.add_child(_name_input)
	_vbox.add_child(HSeparator.new())
	
	# 2. 單人遊戲按鈕
	var btn_single = _create_button("單人遊戲 (Single Player)", _on_single_player_pressed)
	_vbox.add_child(btn_single)
	
	# 分隔線
	_vbox.add_child(HSeparator.new())
	
	# 3. Host 按鈕
	var btn_host = _create_button("建立主機 (Host Game)", _on_host_pressed)
	_vbox.add_child(btn_host)
	
	# 分隔線
	_vbox.add_child(HSeparator.new())
	
	# 3.5 伺服器列表
	var server_label = Label.new()
	server_label.text = "伺服器列表 (Server List):"
	server_label.add_theme_font_size_override("font_size", 32)
	_vbox.add_child(server_label)
	
	_server_list = ItemList.new()
	_server_list.item_selected.connect(_on_server_selected)
	_server_list.custom_minimum_size = Vector2(0, 120) # Reduced height
	_server_list.add_theme_font_size_override("font_size", 24) # Reduced font
	_vbox.add_child(_server_list)
	
	_populate_server_list()
	
	# 4. Join 區域
	var join_hbox = HBoxContainer.new()
	_vbox.add_child(join_hbox)
	
	_ip_input = LineEdit.new()
	_ip_input.placeholder_text = "IP:Port"
	_ip_input.text = "game.dennisfan.work"
	_ip_input.custom_minimum_size.y = 60
	_ip_input.add_theme_font_size_override("font_size", 32)
	_ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_hbox.add_child(_ip_input)
	
	var btn_join = Button.new()
	btn_join.text = "加入 (Join)"
	btn_join.add_theme_font_size_override("font_size", 32)
	btn_join.pressed.connect(_on_join_pressed)
	join_hbox.add_child(btn_join)
	
	# 5. 錯誤訊息彈窗
	_error_dialog = AcceptDialog.new()
	_error_dialog.title = "錯誤"
	add_child(_error_dialog)
	
	# 連接 NetworkManager 訊號
	if not NetworkManager.connection_failed.is_connected(_on_connection_failed):
		NetworkManager.connection_failed.connect(_on_connection_failed)
	if not NetworkManager.server_disconnected.is_connected(_on_server_disconnected):
		NetworkManager.server_disconnected.connect(_on_server_disconnected)

var _error_dialog: AcceptDialog

func _on_connection_failed():
	_show_error("無法連線至伺服器！\n請檢查 IP 與 Port 是否正確。")

func _on_server_disconnected():
	_show_error("與伺服器斷開連線。")

func _show_error(msg: String):
	_error_dialog.dialog_text = msg
	_error_dialog.popup_centered()

func _create_button(text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 40)
	btn.pressed.connect(callback)
	return btn

# ==============================================================================
# Server List Logic
# ==============================================================================

var _server_list_data = [
	{"name": "Official Server", "ip": "game.dennisfan.work", "port": 17777},
	{"name": "Official Server (GB10 - TCP)", "ip": "ws://gb10.dennisfan.work", "port": 443},
	{"name": "Localhost", "ip": "127.0.0.1", "port": 17777}
]

func _populate_server_list():
	_server_list.clear()
	for server in _server_list_data:
		# 如果 Port 不是預設值，或是為了清楚起見，可以顯示出來
		# 這裡為了簡潔，只在選中時填入 input
		_server_list.add_item("%s (%s:%d)" % [server.name, server.ip, server.port])

func _on_server_selected(index: int):
	var data = _server_list_data[index]
	var ip = data.ip
	var port = data.port
	
	# 如果是預設 Port，可以只顯示 IP，但顯示完整 IP:Port 也比較明確
	if port == NetworkManager.DEFAULT_PORT:
		_ip_input.text = ip
	else:
		_ip_input.text = "%s:%d" % [ip, port]
