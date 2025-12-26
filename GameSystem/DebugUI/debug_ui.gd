class_name DebugUI
extends Control


func _ready() -> void:
	DI.register("_debug_ui", self)


func _process(_delta: float) -> void:
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var tps = Engine.physics_ticks_per_second
	var ping = 0
	
	if multiplayer.multiplayer_peer and not multiplayer.is_server():
		# 使用 NetworkManager 的應用層 Ping (支援 UDP 與 TCP)
		ping = NetworkManager.current_latency
			
	%FPSLabel.text = "[color=green][font_size=20]  Fps: {0}\n  TPS: {1}\n  Delay: {2}ms".format(
		[
			fps,
			tps,
			ping
		]
	)
