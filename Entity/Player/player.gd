class_name Player
extends Node2D

@onready var body := %CharacterBody2D

var _debug_draw: DebugDraw
var _light_manager: LightManager


# [Server Auth] Client 輸入會透過 RPC 傳到這裡
var _current_input_vec: Vector2 = Vector2.ZERO

# [Reconciliation] 來自 Server 的權威位置 (用於校正)
var server_sync_position: Vector2 = Vector2.ZERO
var server_sync_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 1. Setup MultiplayerSynchronizer (Authority = Server)
	_setup_multiplayer_synchronizer()
	
	# [IoC] Removed DI.injection(self) - Handled by PlayerManager
	
	# 2. Process Management
	# Server: 負責監控與驗證 (Anti-Cheat / Validation)
	# Client (Authority): 負責完全的移動控制 (Client Authoritative)
	# Client (Puppet): 只負責顯示 (同步後的結果)
	set_process(true)
	# [Fix] 必須開啟 Physics Process，否則 Puppet 不會執行插值移動!
	set_physics_process(true)
	
	# [Fix] 必須開啟 Physics Process，否則 Puppet 不會執行插值移動!
	set_physics_process(true)
	
	
func _setup_multiplayer_synchronizer():
	var synchronizer = MultiplayerSynchronizer.new()
	synchronizer.name = "MultiplayerSynchronizer"
	# [Server Auth] 權限歸 Server (1)
	synchronizer.set_multiplayer_authority(1)
	
	var config = SceneReplicationConfig.new()
	# Sync "server_sync_position" to everyone
	config.add_property(NodePath(".:server_sync_position"))
	config.add_property(NodePath(".:server_sync_velocity"))
	config.add_property(NodePath("CharacterBody2D/AimController/Crosshair:position"))
	
	synchronizer.replication_config = config
	add_child(synchronizer)
	
	
func _on_injected():
	if not _light_manager:
		return
	
	var light = _light_manager.create_light(10)
	%RemoteTransform2D.remote_path = light.get_path()
	tree_exited.connect(light.queue_free)


func get_input_vec() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

func get_attack_vec() -> Vector2:
	return %AimController.get_attack_vec()

func get_player_position() -> Vector2:
	return %CharacterBody2D.global_position


const DECRESS := 20.5
const ACCELATION := 30.3
const MAX_SPEED = 600.0

enum {MOVE, DASH}
var _state: int = MOVE


# RPCs for Input
@rpc("any_peer", "call_local", "unreliable_ordered")
func _server_update_input(vec: Vector2):
	if multiplayer.is_server():
		_current_input_vec = vec

@rpc("any_peer", "call_local", "reliable")
func _server_try_dash():
	if multiplayer.is_server():
		if __dash_timer.is_ready():
			__dir_speed = _current_input_vec * DASH_SPEED
			__dash_timer.trigger(DASH_TIME)
			_state = DASH
			%DASH_particle.emitting = true
			# Sync particle effect to clients? Or rely on Sync?
			# Ideally clients should trigger particle locally on event.
			# For strict server auth, we might need a Multicast RPC for effects.

func _process(delta: float) -> void:
	# Client Only: Gather Input
	if is_multiplayer_authority():
		var input = get_input_vec()
		
		# 傳送 Input 給 Server (頻繁發送)
		_server_update_input.rpc_id(1, input)
		
		if Input.is_action_just_pressed("dash"):
			_server_try_dash.rpc_id(1)
			
	# Draw Lines or other visuals
	#_debug_draw.d_draw_line(...)

func _physics_process(delta: float) -> void:
	# 1. Server: 執行物理，並更新 Sync 變數
	if multiplayer.is_server():
		match _state:
			MOVE: _move(delta)
			DASH: _dash(delta)
		server_sync_position = %CharacterBody2D.position
		server_sync_velocity = body.velocity
	
	# 2. Client (Any): 插值同步 (Strict Server Auth - No Prediction)
	else:
		# 所有 Client (包含自己) 都只負責顯示，完全聽 Server 的
		# 使用較大的 Lerp 係數 (0.4) 讓反應快一點，但仍保持平滑
		%CharacterBody2D.position = %CharacterBody2D.position.lerp(server_sync_position, 0.4)
		body.velocity = server_sync_velocity


## NOTE STATE ZONE 

func _move(dt: float):
	# [Server Only] 使用接收到的 Input
	var input_vec = _current_input_vec
	
	#if input_vec.length() > 0.1:
		#print("[Player] Input Detected: ", input_vec, " Velocity: ", body.velocity)
	var curr_vel: Vector2 = body.velocity
	
	if input_vec.is_zero_approx():
		curr_vel = curr_vel.lerp(Vector2.ZERO, DECRESS * dt)
	else:
		curr_vel = curr_vel.lerp(input_vec * MAX_SPEED, ACCELATION * dt)
	
	body.velocity = curr_vel
	body.move_and_slide()


## Dash Context
const DASH_CD = 0.1 ## NOTE unuse
const DASH_TIME = 0.3
const DASH_SPEED = 2000.0
@export var _dash_curve: Curve
var __dir_speed: Vector2 = Vector2.ZERO
var __dash_timer: CooldownTimer = CooldownTimer.new()

# Removed Duplicate Code

func _dash(dt: float):
	if __dash_timer.is_ready():
		_state = MOVE
		body.velocity = Vector2.ZERO
		return
	var vel = _dash_curve.sample_baked(__dash_timer.get_progress())
	body.velocity = vel * __dir_speed
	body.move_and_slide()


#
