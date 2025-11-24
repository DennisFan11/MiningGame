

class_name BuildingService 
extends Node2D

func _ready() -> void:
	DI.register("_building_service", self)

"""
使用 BuildingManager 為builder & placer 提供建築系統的高度操作封裝
"""


var _building_manager: BuildingManager


# ==============================================================================
# 1. 公開 API - 
# ==============================================================================


func try_set_plan(coord: Vector2i,
	data: BuildingData,
	team: BitmaskManager.TEAM,
	dir: BuildingI.DIR = BuildingI.DIR.UP
	):
	## 有空白 則 可放置
	if _building_manager.is_space(coord): 
		_building_manager.set_block(
			coord, 
			_make_building(
			BuildingDB.TYPE.PLAN,data, coord, team, dir)
		)
	return 


func try_tag_breaking(coord: Vector2i):
	var building: BuildingI = _building_manager.get_block(coord)
	if not building:
		return 
	
	if building is BuildingPlan:
		_building_manager.delete_block(coord)
	
	elif building is BuildingConstruct:
		building.breaking = true
	
	elif building is Building:
		var construct_building: BuildingConstruct = \
			_make_breaking_construct(building.get_data(),
				coord, building.team, building.dir
			)
		_building_manager.set_block(
			coord, construct_building
		)



func try_upgrade(
	coord: Vector2i,
):
	var building: BuildingI = _building_manager.get_block(coord)
	
	if not building: return 
	
	if building is BuildingPlan:
		_building_manager.set_block(coord,
			_make_building(
				BuildingDB.TYPE.CONSTRUCT, building.get_data(), 
				coord, building.team, building.dir
			))
	elif building is BuildingConstruct and building.is_building_finish():
		_building_manager.set_block(coord,
			_make_building(
				BuildingDB.TYPE.BUILDING, building.get_data(), 
				coord, building.team, building.dir
			))


func try_delete(
	coord: Vector2i
):
	var building: BuildingI = _building_manager.get_block(coord)
	
	if not building: return 
	
	if building is BuildingPlan:
		_building_manager.delete_block(coord)
	if building is BuildingConstruct and building.is_remove_finish():
		_building_manager.delete_block(coord)






## PRIVATE 

## 通用建築產生器
func _make_building(
	type: BuildingDB.TYPE,
	data: BuildingData,
	coord: Vector2i,
	team: BitmaskManager.TEAM,
	dir: BuildingI.DIR,
)-> BuildingI:
	
	var instance: BuildingI = BuildingDB.create_type(type, data)
	instance.coord = coord
	instance.team = team
	instance.breaking = false
	instance.dir = dir
	return instance


## 產生一個滿資源標記為拆除的建築
func _make_breaking_construct(
	data: BuildingData, coord: Vector2i,
	team: BitmaskManager.TEAM, dir: BuildingI.DIR,
):
	var instance: BuildingI = BuildingDB.create_type(
		BuildingDB.TYPE.CONSTRUCT, data)
	instance.coord = coord
	instance.team = team
	instance.breaking = true
	instance.dir = dir
	
	instance.contain_item = instance.need_item.dup_self()
	instance.set_breaking_color(true)
	instance.progress = 1.0

	return instance
