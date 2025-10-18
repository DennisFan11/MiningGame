class_name Buildable
extends Node2D

"""
此類別定義建造所需的物件與狀態，包括：
- 所需材料（need_item）
- 內部儲存材料（contain_item）
- 所屬陣營（team）

同時提供建造完成與被移除時的訊號回呼。
"""


@export var need_item: PackedItem

var contain_item: PackedItem

var team: BitmaskManager.TEAM = BitmaskManager.TEAM.IDLE

enum STATE{BUILDING, FINISH, REMOVING, REMOVED}
var state: STATE = STATE.BUILDING

func finished():
	state = STATE.FINISH
	on_finish.emit()
	

func removed():
	state = STATE.REMOVED
	on_removed.emit()

signal on_finish
signal on_removed





# PRIVATE












#
