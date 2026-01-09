class_name UnitMoveComponent
extends Component

var __body_component: BodyComponent
var __data: UnitData

const ACCELATION := 30.3
const DECRESS := 20.5

func _on_data_set(_data: ComponentData):
	pass
	
func _on_setuped():
	if not __body_component or not __body_component.body:
		printerr("[UnitMoveComponent] 缺少 Body Component 或 Body 節點!")
		set_physics_process(false)
		return

	# 只在 Server 執行物理邏輯
	set_physics_process(multiplayer.is_server())

# 輸入提供者 (強型態策略)
# 如果有設定，將優先使用此提供者的 get_input_vector()
var input_provider: UnitInputProvider

func _physics_process(delta: float) -> void:
	# Double check: 只在 Server 執行
	if not multiplayer.is_server():
		return
		
	if not __body_component: return
	
	var body = __body_component.body
	if not body: return

	var input_vec = _get_input_vector()
	var target_vel = Vector2.ZERO
	# 使用 helper 或預設值，注意改用 __data
	var speed = __data.get_speed() if __data else 100.0
	
	if input_vec.length_squared() > 0.01:
		target_vel = input_vec * speed
		body.velocity = body.velocity.lerp(target_vel, ACCELATION * delta)
	else:
		body.velocity = body.velocity.lerp(Vector2.ZERO, DECRESS * delta)
		
	body.move_and_slide()

# 虛擬方法，供覆寫或注入
func _get_input_vector() -> Vector2:
	# 優先使用外部注入的 Input Provider
	if input_provider:
		return input_provider.get_input_vector()
		
	return Vector2.ZERO
