class_name Entity
extends Node2D

"""
擁有組件的的實體 (純容器)
負責持有 LocalInjector 並遞歸初始化組件
"""

func _recursive_call(node: Node):
	if node.has_method("_on_setuped"):
		node._on_setuped()
	for i: Node in node.get_children():
		_recursive_call(i)

var __loca_injector: LocalInjector = LocalInjector.new()

func _ready() -> void:
	__loca_injector.setup(self)

func final_setup():
	await ready
	__loca_injector.injection(self, true)
	_recursive_call(self)

## 獲取指定類型的組件
func get_component(type):
	for child in get_children():
		if is_instance_of(child, type):
			return child
	return null
