class_name DebugUI
extends Control


func _ready() -> void:
	DI.register("_debug_ui", self)


func _process(_delta: float) -> void:
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var tps = Engine.physics_ticks_per_second
	var ping = 0
	
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer is ENetMultiplayerPeer and not multiplayer.is_server():
		var peer = (multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_peer(1)
		if peer:
			ping = peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
			
	%FPSLabel.text = "[color=green][font_size=20]  Fps: {0}\n  TPS: {1}\n  Delay: {2}ms".format(
		[
			fps,
			tps,
			ping
		]
	)
