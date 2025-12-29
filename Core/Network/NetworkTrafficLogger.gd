class_name NetworkTrafficLogger
extends Node

const TRAFFIC_LOG_INTERVAL = 5.0

var _traffic_log_timer: float = 0.0
var _total_bytes_sent: int = 0
var _total_bytes_received: int = 0

func _process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server():
		return

	# Only works with ENet for now
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		_traffic_log_timer += delta
		if _traffic_log_timer >= TRAFFIC_LOG_INTERVAL:
			_traffic_log_timer = 0.0
			_log_traffic_stats()

func _log_traffic_stats():
	var peer = multiplayer.multiplayer_peer
	if not peer or not (peer is ENetMultiplayerPeer): return
	
	var host = peer.host
	if not host: return
	
	# pop_statistic returns the value since last call and resets internal counter for that stat
	var incoming = host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA)
	var outgoing = host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
	
	_total_bytes_received += incoming
	_total_bytes_sent += outgoing
	
	var in_rate = (incoming / TRAFFIC_LOG_INTERVAL) / 1024.0 # KB/s
	var out_rate = (outgoing / TRAFFIC_LOG_INTERVAL) / 1024.0 # KB/s
	
	var total_in_mb = _total_bytes_received / (1024.0 * 1024.0)
	var total_out_mb = _total_bytes_sent / (1024.0 * 1024.0)
	
	print("[Traffic] Rate In/Out: %.2f/%.2f KB/s | Total In/Out: %.2f/%.2f MB" % [in_rate, out_rate, total_in_mb, total_out_mb])
