class_name BuildingService
extends Node2D

func _ready() -> void:
	DI.register("_building_service", self)

"""
使用 BuildingManager 為builder & placer 提供建築系統的高度操作封裝
"""


var _building_manager: BuildingManager

# ==============================================================================
# 1. 公開 API (RPC Wrappers)
# ==============================================================================

# ... existing code ...

# ... existing code ...

func try_transfer_resource(coord: Vector2i, amount: PackedItem, repo: PlayerItemRepo):
	# Dual Simulation: Both Server and Client execute this locally
	var building = _building_manager.get_block(coord)
	
	# New Controller Support
	if not (building is BuildingController): return
	
	if building.stage != BuildingController.STAGE.CONSTRUCT: return
	
	# Exec Transaction
	repo.contain = repo.contain.sub(amount)
	building.contain_item = building.contain_item.add(amount)
	building.update_progress()
	
	# Auto Finish Check (Server Only)
	if multiplayer.is_server():
		if amount.vtotal() > 0: # Building
			if building.is_building_finish():
				request_upgrade(coord)
		else: # Removing
			if building.is_remove_finish():
				request_delete(coord)

# ... existing code ...

# ==============================================================================
# 1. 公開 API - 
# ==============================================================================


# ==============================================================================
# 1. 公開 API (RPC Wrappers)
# ==============================================================================

func try_set_plan(coord: Vector2i, data: BuildingData, state: BuildingState):
	if multiplayer.is_server():
		request_build_plan(coord, data.get_script().resource_path, state.to_dict())
	else:
		request_build_plan.rpc_id(1, coord, data.get_script().resource_path, state.to_dict())

func try_tag_breaking(coord: Vector2i):
	if multiplayer.is_server():
		request_tag_breaking(coord)
	else:
		request_tag_breaking.rpc_id(1, coord)

func try_upgrade(coord: Vector2i):
	if multiplayer.is_server():
		request_upgrade(coord)

func try_delete(coord: Vector2i):
	if multiplayer.is_server():
		request_delete(coord)


# ==============================================================================
# 2. Server RPC Implementation
# ==============================================================================

@rpc("any_peer")
func request_build_plan(coord: Vector2i, data_uid: String, state_dict: Dictionary):
	if not multiplayer.is_server(): return
	
	# Logic Check
	if _building_manager.is_space(coord):
		var data_script = load(data_uid)
		var data = data_script.new()
		var state = BuildingState.from_dict(state_dict)
		
		# Execute
		_building_manager.spawn_building(BuildingDB.TYPE.PLAN, data, state)


@rpc("any_peer")
func request_tag_breaking(coord: Vector2i):
	if not multiplayer.is_server(): return
	
	var building: Node = _building_manager.get_block(coord)
	if not building: return
	
	if building is BuildingController:
		match building.stage:
			BuildingController.STAGE.PLAN:
				_building_manager.delete_block(coord)
			BuildingController.STAGE.CONSTRUCT:
				building.breaking = true
			BuildingController.STAGE.COMPLETE:
				building.stage = BuildingController.STAGE.CONSTRUCT
				building.contain_item = building.get_need_item()
				building.breaking = true
				building.update_progress()


@rpc("any_peer")
func request_upgrade(coord: Vector2i):
	if not multiplayer.is_server(): return
	
	var building: Node = _building_manager.get_block(coord)
	if not building: return
	
	if building is BuildingController:
		match building.stage:
			BuildingController.STAGE.PLAN:
				building.stage = BuildingController.STAGE.CONSTRUCT
			BuildingController.STAGE.CONSTRUCT:
				if building.is_building_finish():
					building.stage = BuildingController.STAGE.COMPLETE


@rpc("any_peer")
func request_delete(coord: Vector2i):
	if not multiplayer.is_server(): return
	
	var building: Node = _building_manager.get_block(coord)
	if not building: return
	
	if building is BuildingController:
		match building.stage:
			BuildingController.STAGE.PLAN:
				_building_manager.delete_block(coord)
			BuildingController.STAGE.CONSTRUCT:
				if building.is_remove_finish():
					_building_manager.delete_block(coord)

## PRIVATE - Helper functions removed (Unused)
