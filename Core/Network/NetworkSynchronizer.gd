class_name NetworkSynchronizer extends Node

## NetworkSynchronizer
## 取代 MultiplayerSynchronizer，提供無依賴、魯棒性強的屬性同步方案。
## 支援插值 (Interpolation)、強制同步 (Snap) 以及斷線重連後的狀態恢復。

# ==============================================================================
# 配置設定
# ==============================================================================

## 同步根節點路徑 (預設為父節點)
@export var root_path: NodePath = ".."

## 同步間隔 (秒)
@export var sync_interval: float = 0.05

## 插值速度 (Lerp Weight)
## 數值越高追蹤越快 (35.0 約 0.1s 延遲)，但過高可能導致抖動。
@export var interpolation_speed: float = 35.0

## 強制同步閾值 (Snap Margin)
## 當數值差距超過此值時，將直接強制設定而不進行插值 (Teleport)，防止滑步。
@export var snap_margin: float = 300.0

## 是否僅同步變更的值 (節省頻寬)
@export var specific_check_on_change: bool = true

# ==============================================================================
# 內部狀態
# ==============================================================================

class PropConfig:
	var id: int; var full_path: NodePath; var node_path: NodePath; var prop: String
	var last_val: Variant; var interpolate: bool; var target_val: Variant; var is_angle: bool

var _props: Array[PropConfig] = []
var _id_map: Dictionary = {}
var _timer: Timer

func _ready() -> void:
	if multiplayer.is_server():
		_timer = Timer.new(); _timer.wait_time = sync_interval; _timer.autostart = true
		_timer.timeout.connect(_on_timer); add_child(_timer)
	else:
		# Client 需要 process 進行插值運算
		set_process(true)

# ==============================================================================
# Public API
# ==============================================================================

## 新增同步屬性
## @param interpolate: 是否啟用客戶端插值 (建議對 Position/Rotation 啟用)
func add_property(path: NodePath, interpolate: bool = false) -> void:
	var c = PropConfig.new(); c.id = _props.size(); c.full_path = path; c.interpolate = interpolate
	var ns = path.get_concatenated_names(); c.node_path = NodePath(ns) if ns else NodePath(".")
	c.prop = path.get_concatenated_subnames()
	# 自動偵測是否為角度屬性，使用 lerp_angle
	c.is_angle = "rotation" in c.prop or "angle" in c.prop
	_props.append(c); _id_map[c.id] = c

## 客戶端手動請求初始同步 (Late Join support)
func start() -> void:
	if multiplayer.is_server(): return
	await get_tree().process_frame
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_req_sync.rpc_id(1)

# ==============================================================================
# Client Logic (Interpolation)
# ==============================================================================

func _process(delta: float) -> void:
	if multiplayer.is_server(): return
	var root = get_node_or_null(root_path)
	if not root: return
	
	for c in _props:
		if not c.interpolate or c.target_val == null: continue
		var n = root.get_node_or_null(c.node_path)
		if not n: continue
		var cur = n.get(c.prop)
		if typeof(cur) != typeof(c.target_val): continue
		
		# 使用 min 限制權重，防止 FPS 過低時數值衝過頭
		var w = min(delta * interpolation_speed, 1.0)
		n.set(c.prop, lerp_angle(cur, c.target_val, w) if c.is_angle and cur is float else lerp(cur, c.target_val, w))

# ==============================================================================
# Server Logic (Collection & Broadcast)
# ==============================================================================

func _on_timer() -> void:
	var data = _collect_state(not specific_check_on_change)
	if not data.is_empty(): _rpc_unreliable.rpc(data)

@rpc("any_peer", "call_remote", "reliable")
func _req_sync() -> void:
	# 回應 Late Join 請求 (Reliable)
	if multiplayer.is_server():
		_rpc_reliable.rpc_id(multiplayer.get_remote_sender_id(), _collect_state(true))

func _collect_state(force_all: bool) -> Dictionary:
	var root = get_node_or_null(root_path); var data = {}
	if not root: return data
	for c in _props:
		var n = root.get_node_or_null(c.node_path)
		if not n:
			c.last_val = null; continue # 節點丟失，重置上次狀態以便復原時同步
		var v = n.get(c.prop)
		if force_all or c.last_val == null or v != c.last_val:
			data[c.id] = v; c.last_val = v
	return data

# ==============================================================================
# Client Logic (Application)
# ==============================================================================

@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_unreliable(data: Dictionary) -> void: _apply(data)

@rpc("authority", "call_remote", "reliable")
func _rpc_reliable(data: Dictionary) -> void: _apply(data)

func _apply(data: Dictionary) -> void:
	var root = get_node_or_null(root_path)
	if not root: return
	for id in data:
		if not _id_map.has(id): continue
		var c = _id_map[id]; var val = data[id]; var n = root.get_node_or_null(c.node_path)
		if not n: continue
		
		if c.interpolate:
			# 強制同步檢查 (Teleport if too far)
			var cur = n.get(c.prop)
			if (val is Vector2 or val is Vector3) and typeof(cur) == typeof(val) and cur.distance_to(val) > snap_margin:
				n.set(c.prop, val) # 直接設定
			c.target_val = val
		else:
			n.set(c.prop, val)
