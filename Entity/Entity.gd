class_name Entity
extends Node2D

"""
擁有組件的的實體
"""

func _recursive_call(node: Node):
	if node is Component:
		await node._entity_ready(self)
	for i:Node in node.get_children():
		await _recursive_call(i)



func _ready() -> void:
	_recursive_call(self)

#func _entity_ready():
	#pass
