class_name Entity
extends Node2D

"""
擁有組件的的實體
"""

func _recursive_call(node: Node):
	#if node is Component:
	if node.has_method("_on_setuped"):
		node._on_setuped()
	for i:Node in node.get_children():
		_recursive_call(i)

var __loca_injector: LocalInjector = LocalInjector.new()


func _ready() -> void:
	__loca_injector.setup(self)
	
	

func set_components(components: Array[BuildingDB.ComponentData]):
	for i: BuildingDB.ComponentData in components:
		add_child(i.scene)
		__loca_injector.register(i.path, i.scene)
	

func final_setup():
	await ready
	__loca_injector.injection(self, true)
	_recursive_call(self)
	
"""
if child.has_method("_on_setuped"):
	child._on_setuped()

"""
