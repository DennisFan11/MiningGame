class_name BuildingDB
extends Node

"""
提供 建築資料存取 及 建築實例生成
通過 BuildingData 生成建築
"""
enum TYPE{ PLAN, CONSTRUCT, BUILDING }

## Factory 產生一個遊戲建築
static func create_type(type: TYPE, data: BuildingData):
	match type:
		TYPE.PLAN:
			print("PLAN")
			return BuildingDB.create_plan(data)
		TYPE.CONSTRUCT:
			print("CONSTRUCT")
			return BuildingDB.create_construct(data)
		TYPE.BUILDING:
			print("BUILDING")
			return BuildingDB.create_building(data)
		_:
			return null
	return null

static func create_plan(data: BuildingData)-> BuildingPlan:
	var node: BuildingI = preload("uid://dywvpop5avhnn").instantiate()
	node.set_data(data)
	return node
static func create_construct(data: BuildingData)-> BuildingConstruct:
	var node: BuildingI = preload("uid://dmqko2wm6gy7a").instantiate()
	node.set_data(data)
	return node
static func create_building(data: BuildingData)-> Building:
	var node: BuildingI = preload("uid://dgmf1d3lpy1rg").instantiate()
	node.set_data(data)
	return node










static func get_types()-> Array[BuildingType]:
	return types.values()



## 建築類型基類 對 UI 暴露 ! ! !
class BuildingType:
	extends RefCounted
	
	func get_buildings(): return _buildings
	func get_name(): return _name
	
	var _buildings: Array[BuildingData] = []
	var _name: StringName
	func _init(_name: StringName) -> void:
		self._name = _name


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
	_register_type(&"Core")
	_register_type(&"Logistics")
	_register_type(&"Wall")
	
	## placeholder
	var dummy_building = preload("uid://c744h4epou4k").new() 
	
	_register_building(&"Core", dummy_building)
	_register_building(&"Core", dummy_building)
	_register_building(&"Core", preload("uid://dndfj7pffk2w8").new())
	_register_building(&"Logistics", dummy_building)
	_register_building(&"Logistics", dummy_building)
	_register_building(&"Logistics", dummy_building)
	_register_building(&"Wall", dummy_building)
	_register_building(&"Wall", dummy_building)
	_register_building(&"Wall", dummy_building)
	
	
	
