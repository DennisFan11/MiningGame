class_name MainMenu
extends Node2D

## Main Menu with Dynamic UI Generation
## 負責產生主選單介面並連接 NetworkManager

# UI Components
var _vbox: VBoxContainer
var _ip_input: LineEdit
var _name_input: LineEdit

func _ready() -> void:
	_setup_ui()

# ==============================================================================
# Business Logic (Events)
# ==============================================================================

func _on_single_player_pressed() -> void:
	_save_player_info()
	print("啟動單人模式...")
	NetworkManager.start_host(true) # true = single player mode

func _on_host_pressed() -> void:
	_save_player_info()
	print("啟動區域連線主機...")
	NetworkManager.start_host(false) # false = multiplayer mode

func _on_join_pressed() -> void:
	_save_player_info()
	var ip = _ip_input.text
	if ip.is_empty():
		ip = "127.0.0.1"
	print("嘗試加入伺服器: ", ip)
	
	NetworkManager.join_game(ip)

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
	_vbox.offset_left = -150
	_vbox.offset_top = -150
	_vbox.offset_right = 150
	_vbox.offset_bottom = 150
	_vbox.add_theme_constant_override("separation", 10)
	control.add_child(_vbox)
	
	# 1. 標題
	var label = Label.new()
	label.text = "Miningame Multiplayer"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(label)
	
	# 1.5 玩家名稱輸入
	_vbox.add_child(Label.new()) # Spacer
	var name_label = Label.new()
	name_label.text = "Player Name:"
	_vbox.add_child(name_label)
	
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Enter Name"
	_name_input.text = "Player"
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
	
	# 4. Join 區域
	var join_hbox = HBoxContainer.new()
	_vbox.add_child(join_hbox)
	
	_ip_input = LineEdit.new()
	_ip_input.placeholder_text = "127.0.0.1"
	_ip_input.text = "127.0.0.1"
	_ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_hbox.add_child(_ip_input)
	
	var btn_join = Button.new()
	btn_join.text = "加入 (Join)"
	btn_join.pressed.connect(_on_join_pressed)
	join_hbox.add_child(btn_join)

func _create_button(text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.pressed.connect(callback)
	return btn
