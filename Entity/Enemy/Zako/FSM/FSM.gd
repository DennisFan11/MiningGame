class_name FSM
extends Node2D




@export var body: Enemy

func _ready() -> void:
	register("_fsm", self)
	register("_body", body)
	get_tree().node_added.connect(_injection)
	# 遞歸重新注入
	injection(self, true)

func _process(dt: float) -> void:
	if not _current_state:
		return 
	_current_state.handle_process(dt)
func _physics_process(delta: float) -> void:
	if not _current_state:
		return 
	_current_state.handle_physics_process(delta)
func _input(event: InputEvent) -> void:
	if not _current_state:
		return 
	_current_state.handle_input(event)

func change_state(new_state: FSM_state):
	if _current_state : _current_state.exit()
	_current_state = new_state
	if _current_state : _current_state.enter()



@export var _current_state: FSM_state









## NOTE 區域型 動態反射依賴注入器

## 依賴表
var _dependence: Dictionary = { # property : Object
}

## 註冊依賴項目
func register(property: String, instance) -> void:
	_dependence[property] = instance

## 手動獲取依賴 (由 GameLoop Manager觸發 確保所有依賴項目以註冊)
func injection(target_node: Node, recursive: bool=false):
	#print("injection: ", target_node)
	
	## 遞歸注入
	if recursive:
		for child: Node in target_node.get_children():
			await injection(child, true)
	
	await _injection(target_node)

## 自動獲取依賴
func _injection(target_node: Node):
	for property:String in _dependence.keys():
		if property in target_node:
			target_node.set(property, _dependence[property])
	if target_node.has_method("_on_injected"):
		target_node._on_injected()
