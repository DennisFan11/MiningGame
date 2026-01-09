class_name BuildingDB
extends Node

"""
提供 建築資料存取 及 建築實例生成
通過 BuildingData 生成建築
"""
enum TYPE {PLAN, CONSTRUCT, BUILDING, FULL_REMOVED_CONSTRUCT}

## Factory 產生一個遊戲建築
const CONTROLLER_SCENE = preload("res://Entity/Building/BuildingController.tscn")

## Factory 產生一個遊戲建築
static func create_type(
		type: TYPE,
		data: BuildingData,
		state: BuildingState) -> Node:
	var instance = CONTROLLER_SCENE.instantiate()
	# 設定基礎屬性
	instance.data = data
	# 設定狀態 (Coord, Team, etc.)
	# BuildingController 沒有直接對應 BuildingState 類別，而是屬性分散
	# 我們需手動 mapping 或讓 BuildingController 接受 BuildingState
	# 目前 Controller 有: coord, team, dir
	instance.coord = state.coord
	instance.team = state.team
	instance.dir = state.dir
	
	match type:
		TYPE.PLAN:
			instance.stage = BuildingController.STAGE.PLAN
		TYPE.CONSTRUCT:
			instance.stage = BuildingController.STAGE.CONSTRUCT
		TYPE.BUILDING:
			instance.stage = BuildingController.STAGE.COMPLETE
		TYPE.FULL_REMOVED_CONSTRUCT:
			instance.stage = BuildingController.STAGE.CONSTRUCT
			instance.breaking = true
			instance.contain_item = data.get_need_item() # Full items
			instance.update_progress()
		_:
			assert(false, "BuildingTYPE not valid !")

	return instance

# Legacy helpers replacement (optional, or just remove)
static func create_plan(data: BuildingData) -> Node:
	var node = CONTROLLER_SCENE.instantiate()
	node.data = data
	node.stage = BuildingController.STAGE.PLAN
	return node

static func create_construct(data: BuildingData) -> Node:
	var node = CONTROLLER_SCENE.instantiate()
	node.data = data
	node.stage = BuildingController.STAGE.CONSTRUCT
	return node

static func create_building(data: BuildingData) -> Node:
	var node = CONTROLLER_SCENE.instantiate()
	node.data = data
	node.stage = BuildingController.STAGE.COMPLETE
	return node

## COMPONENTS


static func get_types() -> Array[BuildingType]:
	return types.values()


## 建築類型基類 對 UI 暴露 ! ! !
class BuildingType:
	extends RefCounted
	
	func get_buildings(): return _buildings
	func get_name(): return _name
	
	var _buildings: Array[BuildingData] = []
	var _name: StringName
	func _init(__name: StringName) -> void:
		self._name = __name


##================ PRIVATE ===============
## 建築類別表
static var types: Dictionary[StringName, BuildingType] = {}


##================ 操作 ===============

static func _register_type(type_name: StringName):
	types.set(type_name, BuildingType.new(type_name))

static func _register_building(type: StringName, data: BuildingData):
	assert(types.has(type))
	types[type]._buildings.append(data)
	

static func _static_init() -> void:
	_register_type(&"Logistics")
	_register_type(&"Wall")
	_register_type(&"Core")
	
	## placeholder
	var dummy_building = preload("uid://c744h4epou4k").new()
	
	
	_register_building(&"Logistics", preload("uid://b80a8i742nfn7").new())
	_register_building(&"Logistics", preload("uid://dek47g0e1b0mj").new())
	_register_building(&"Logistics", preload("uid://cc4u1gcby6aen").new())
	_register_building(&"Core", dummy_building)
	_register_building(&"Core", dummy_building)
	_register_building(&"Core", preload("uid://dndfj7pffk2w8").new())
	_register_building(&"Wall", dummy_building)
	_register_building(&"Wall", dummy_building)
	_register_building(&"Wall", dummy_building)
