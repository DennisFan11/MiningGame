class_name DebugUI
extends Control


func _ready() -> void:
	DI.register("_debug_ui", self)


func _process(_delta: float) -> void:
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var tps = Engine.physics_ticks_per_second
	var ping = 0
	
	if _current_latency > 0:
		ping = _current_latency
	elif multiplayer.multiplayer_peer and multiplayer.multiplayer_peer is ENetMultiplayerPeer and not multiplayer.is_server():
		# Fallback if ping system not ready yet
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

#
# Ping Logic
#
var _ping_timer: float = 0.0
var _current_latency: int = 0

func _input(event):
	# Toggle Ping with F3
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_send_ping()

func _physics_process(delta):
	# Simple timer implementation
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		_ping_timer += delta
		if _ping_timer >= 1.0: # 1 second interval
			_ping_timer = 0.0
			_send_ping()

func _send_ping():
	# Client -> Server
	_remote_ping_request.rpc_id(1, Time.get_ticks_msec())

@rpc("any_peer", "call_remote", "unreliable")
func _remote_ping_request(client_time: int):
	# Server runs this
	var sender_id = multiplayer.get_remote_sender_id()
	_remote_pong_response.rpc_id(sender_id, client_time)

@rpc("authority", "call_remote", "unreliable")
func _remote_pong_response(client_time: int):
	# Client runs this
	var now = Time.get_ticks_msec()
	_current_latency = now - client_time
