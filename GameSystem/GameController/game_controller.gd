class_name GameController
extends Node2D


func _recursive_call(node: Node, method: String):
	if node.has_method(method):
		node.call(method)
	for i: Node in node.get_children():
		_recursive_call(i, method)


func _ready() -> void:
	# 註冊 GameManager 到 DI 系統
	DI.register("_game_controller", self)
	
	# 遞歸重新注入
	DI.injection(self, true)

	_recursive_call(self, "_game_start")
	
	# [Client Only] 場景載入完成後才登入，確保 PlayerManager/Spawner 已就緒
	if not multiplayer.is_server():
		var my_name = NetworkManager.player_info.get("name", "Client")
		var my_uid = str(randi())
		print("Client: 場景載入完畢，請求登入: ", my_name)
		AuthManager.login(my_uid, my_name)

	
func stop_game():
	process_mode = Node.PROCESS_MODE_DISABLED
func continue_game():
	process_mode = Node.PROCESS_MODE_ALWAYS


## 設定新的時間速率
func set_game_scale(new_scale: float, TIME: float) -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(Engine, "time_scale", new_scale, TIME)

## 取得遊戲時間速率
func get_game_scale() -> float:
	return Engine.time_scale
