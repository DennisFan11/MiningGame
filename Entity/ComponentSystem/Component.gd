@abstract
class_name Component
extends Node2D


## component data 注入
func _on_data_set(data: ComponentData):
	pass

## 全域 DI 注入
func _on_injected():
	pass

## Entity 初始化注入完成 
func _on_setuped():
	pass
