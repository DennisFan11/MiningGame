class_name PlayerControllerComponent
extends Component

## 玩家控制器組件
## 負責：收集玩家輸入 → RPC 到 Server → 提供給 UnitMoveComponent

var __unit_move_component: UnitMoveComponent
var __body_component: BodyComponent

## 輸入動作名稱配置
var action_left: String = "left"
var action_right: String = "right"
var action_up: String = "up"
var action_down: String = "down"
var action_dash: String = "dash"

signal on_dash_requested

func _ready() -> void:
	add_child(Camera2D.new())

func _process(_delta: float) -> void:
	
	# Client Only: 收集輸入
	if not is_multiplayer_authority():
		return
	
	global_position = __body_component.body.global_position
	
	# 收集移動輸入
	var input = Input.get_vector(action_left, action_right, action_up, action_down)
	
	# 發送到 Server（頻繁發送，unreliable）
	_rpc_update_input.rpc_id(1, input)
	
	# 衝刺輸入（偶發事件，reliable）
	if Input.is_action_just_pressed(action_dash):
		_rpc_dash.rpc_id(1)

## Server 端接收輸入
@rpc("any_peer", "call_local", "unreliable_ordered")
func _rpc_update_input(input_vec: Vector2):
	if not multiplayer.is_server():
		return
	
	# 更新 Provider 的數據
	if _input_provider:
		_input_provider.current_input = input_vec

@rpc("any_peer", "call_local", "reliable")
func _rpc_dash():
	if not multiplayer.is_server():
		return
	
	on_dash_requested.emit()

# ==============================================================================
# Input Provider Implementation
# ==============================================================================

var _input_provider: PlayerInputProvider

## 內部類別：專門給 PlayerController 用的 Provider
class PlayerInputProvider extends UnitInputProvider:
	var current_input: Vector2 = Vector2.ZERO
	func get_input_vector() -> Vector2:
		return current_input

func _on_setuped():
	# 創建並註冊 Provider
	if __unit_move_component:
		_input_provider = PlayerInputProvider.new()
		__unit_move_component.input_provider = _input_provider
	
	# 初始化 Process 狀態
	if is_multiplayer_authority():
		set_process(true)
	else:
		set_process(false)
