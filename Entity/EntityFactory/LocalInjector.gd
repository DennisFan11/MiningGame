class_name LocalInjector
extends Node

## DI 動態反射本地注入器


## 初始化：監聽容器
func setup(container: Node):
	# 連結信號，當有新節點進入容器時觸發
	if not container.child_entered_tree.is_connected(_injection):
		container.child_entered_tree.connect(_injection)








## 依賴表
var _dependence: Dictionary = { # property : Object
}

## 註冊依賴項目
func register(property: String, instance) -> void:
	_dependence[property] = instance

## 手動獲取依賴 (由 GameLoop Manager觸發 確保所有依賴項目以註冊)
func injection(target_node: Node, recursive: bool=false):
	## 遞歸注入
	if recursive:
		for child: Node in target_node.get_children():
			injection(child, true)
	_injection(target_node)
	



## 自動獲取依賴
func _injection(target_node: Node):
	for property:String in _dependence.keys():
		if property in target_node:
			print("inject "+ str(property) + " on ", target_node)
			target_node.set(property, _dependence[property])
			#print("result: ", target_node[property])
	

## 遞歸更新
func re_inject(target_node: Node, property: String, instance):
	register(property, instance)
	_re_inject(target_node, property, instance)

func _re_inject(target_node: Node, property: String, instance):
	for child: Node in target_node.get_children():
		_re_inject(child, property, instance)
	if property in target_node:
		target_node.set(property, instance)




"""
func _ready() -> void:
	DI.register("_tilemap_manager", self)
## 
func _on_setuped(): 
	pass
"""









#
