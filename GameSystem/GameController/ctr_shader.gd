extends ColorRect

func _ready():
	# 連接主視窗的 size_changed 信號
	# get_tree().root 代表主視窗 (Window)
	get_tree().root.size_changed.connect(_on_window_size_changed)

func _on_window_size_changed():
	# 獲取新的視窗大小
	var current_size = get_tree().root.size
	print("視窗大小已變更為: ", current_size)
	const RATIO = Vector2(1280, 960) / Vector2(1613, 907)
	(material as ShaderMaterial).set_shader_parameter("resolution", Vector2(current_size)* RATIO)
	

	# 如果你需要的是螢幕本身的解析度 (例如全螢幕模式下)，可以使用 DisplayServer
	# var screen_size = DisplayServer.screen_get_size()
