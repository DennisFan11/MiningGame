class_name HitboxComponent
extends Component

var __body_component: BodyComponent
var _bitmask_manager: BitmaskManager
var _team: int

var hitbox_area: Area2D

func _on_data_set(data: ComponentData):
	if data is HitboxComponentData:
		_team = data.team

func _on_setuped():
	if not __body_component or not __body_component.body:
		printerr("[HitboxComponent] Missing BodyComponent!")
		return
	
	# 創建 Area2D 作為 Hitbox (Hurtbox)
	hitbox_area = Area2D.new()
	hitbox_area.name = "Hitbox"
	
	# Hurtbox 設定：不主動偵測別人 (monitoring=false)，但也要讓別人打得到 (monitorable=true)
	hitbox_area.monitoring = false
	hitbox_area.monitorable = true
	
	# 將 hitbox 添加到 body 下（與 body 一起移動）
	__body_component.body.add_child(hitbox_area)
	
	# 複製 body 的碰撞形狀給 hitbox
	_copy_collision_shape()
	
	# 嘗試配置層級 (如果 DI 在此之前已完成)
	_configure_collision()

func _on_injected():
	# 當此組件被注入全域依賴後呼叫
	_configure_collision()

func _configure_collision():
	if not hitbox_area or not _bitmask_manager:
		return
		
	# 設定碰撞層級（基於 Team）
	# Layer: 自己是誰 (讓子彈來撞)
	# Mask:  0 (Hitbox 不主動去撞別人，只等著被撞)
	hitbox_area.collision_layer = _bitmask_manager.get_self_layer(_team)
	hitbox_area.collision_mask = 0

func _copy_collision_shape():
	# 從 body 複製 CollisionShape2D
	for child in __body_component.body.get_children():
		if child is CollisionShape2D:
			var hitbox_shape = CollisionShape2D.new()
			hitbox_shape.shape = child.shape
			hitbox_area.add_child(hitbox_shape)
			break
		elif child is CollisionPolygon2D:
			var hitbox_shape = CollisionPolygon2D.new()
			hitbox_shape.polygon = child.polygon
			hitbox_area.add_child(hitbox_shape)
			break
