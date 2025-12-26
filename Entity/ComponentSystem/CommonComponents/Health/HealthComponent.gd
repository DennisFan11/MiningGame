class_name HealthComponent
extends Component

var max_hp: float = 100.0
var current_hp: float = 100.0

signal on_damaged(amount, source)
signal on_die

func _on_data_set(data: ComponentData):
	if data is HealthComponentData:
		max_hp = data.max_hp
		current_hp = max_hp

## Public API - 自動處理 RPC
func damage(amount: float, source: Node = null):
	if multiplayer.is_server():
		_apply_damage(amount, source)
	else:
		_rpc_damage.rpc_id(1, amount, source.get_path() if source else NodePath())

func heal(amount: float):
	if multiplayer.is_server():
		_apply_heal(amount)
	else:
		_rpc_heal.rpc_id(1, amount)

## Server Authority - 實際執行邏輯
func _apply_damage(amount: float, source: Node = null):
	current_hp -= amount
	on_damaged.emit(amount, source)
	
	if current_hp <= 0:
		_die()

func _apply_heal(amount: float):
	current_hp = min(current_hp + amount, max_hp)

## RPCs
@rpc("any_peer", "call_local", "reliable")
func _rpc_damage(amount: float, source_path: NodePath):
	if not multiplayer.is_server(): return
	var source_node = get_node_or_null(source_path) if source_path != NodePath() else null
	_apply_damage(amount, source_node)

@rpc("any_peer", "call_local", "reliable")
func _rpc_heal(amount: float):
	if not multiplayer.is_server(): return
	_apply_heal(amount)

## Death
func _die():
	on_die.emit()
	# Server 負責刪除實體
	if multiplayer.is_server():
		get_parent().queue_free()
