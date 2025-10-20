class_name Building
extends Node2D

"""
建築基類
"""



@onready var buildable := %Buildable
@onready var iff := %IFF


func set_team(team: BitmaskManager.TEAM):
	buildable.team = team
	iff.team = team


func get_buildable()-> Buildable:
	return %Buildable









#

## 建築完成
func _on_buildable_on_finish() -> void:
	pass # Replace with function body.

## 拆除作業
func _on_buildable_on_removing() -> void:
	pass # Replace with function body.

## 拆除完成
func _on_buildable_on_removed() -> void:
	queue_accessibility_update()
