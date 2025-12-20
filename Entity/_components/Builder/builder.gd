class_name Builder
extends Node2D

var _player_item_repo: PlayerItemRepo
var BUILDING_SPEED: float = 3.0 ## item/s

enum {IDLE, RUNNING}
var state: int = RUNNING

@onready var _IFF = %IFF

var _building_service: BuildingService

var team: BitmaskManager.TEAM = BitmaskManager.TEAM.IDLE:
	set(new):
		team = new
		_IFF.team = new

#var _building_plan_queue: Array[BuildingPlan] = []


func _process(delta: float) -> void:
	# Run on everyone (Server, Owner, Puppet)
	match state:
		IDLE:
			pass
		RUNNING:
			%BuildingEffect.visible = false
			%BuildingEffect.global_transform.origin = Vector2.ONE

			#print("target: ", _IFF.get_targets())
			for i in _IFF.get_sorted_targets(global_position):
				if not is_instance_valid(i):
					continue
				if i is BuildingPlan:
					_try_upgrade(i.state.coord)
					__update_polygon(i)
					break
				if i is BuildingConstruct:
					__update_polygon(i, i.breaking)
					if i.breaking:
						_remove(i, delta)
						break
					else:
						_build(i, delta)
						break


func __update_polygon(i: BuildingEntity, breaking: bool = false):
	var polygon = i.get_global_points()
	polygon.append(global_position)
	polygon = Geometry2D.convex_hull(polygon)
	%BuildingEffect.visible = true
	
	%BuildingPolygon.polygon = polygon
	%BuildingPolygon.color = ColorDB.get_building_color(false, breaking)
	%BuildingLine.points = polygon
	%BuildingLine.default_color = ColorDB.get_building_color(true, breaking)


## 建築操作


func _try_upgrade(coord: Vector2i):
	_building_service.try_upgrade(coord)
func _try_delete(coord: Vector2i):
	_building_service.try_delete(coord)


#region move res

## 建造一個建築
func _build(building: BuildingConstruct, dt: float) -> void:
	# 擁有的資源
	var have: PackedItem = _player_item_repo.contain

	# 原始缺口
	var need: PackedItem = building.need_item.sub(building.contain_item)

	# 只取正缺口（負值清為 0）
	var need_pos: PackedItem = need.vmax(PackedItem.zero())
	var need_total: float = need_pos.vtotal()

	# 若無正缺口或吞吐為 0 → 完成 (Server 會自動 Upgrade，這裡只需等待)
	var item_speed := BUILDING_SPEED * dt
	if is_zero_approx(need_total):
		return

	# 計算請求量（不超過存量）
	var request: PackedItem = need_pos.mul(item_speed / need_total)
	var moving: PackedItem = have.vmin(request)

	# 收尾保險：逐項夾在 [0, need_pos] 內，避免浮點誤差
	moving = moving.vclamp(PackedItem.zero(), need_pos)

	# Dual Simulation Execution (Direct Call)
	if not moving.is_zero():
		_building_service.try_transfer_resource(building.state.coord, moving, _player_item_repo)

## 移除一個建築
func _remove(building: BuildingConstruct, dt: float) -> void:
	# 僅保留正值（負值清 0）
	var give_back := building.contain_item.vmax(PackedItem.zero())
	var total_back := give_back.vtotal()

	## 無可退 → 完成 (Server 自動 Delete)
	var item_speed := BUILDING_SPEED * dt
	if is_zero_approx(total_back):
		if multiplayer.is_server() and building.breaking:
			_building_service.try_delete(building.state.coord)
		return

	# 依比例限制本 tick 退回總量 cap
	var request := give_back.mul(min(1.0, item_speed / total_back))

	# 逐項保險：夾在 [0, give_back]（避免浮點誤差）
	request = request.vclamp(PackedItem.zero(), give_back)
	
	# Dual Simulation Execution (Direct Call)
	if not request.is_zero():
		var negative_request = PackedItem.zero().sub(request)
		_building_service.try_transfer_resource(building.state.coord, negative_request, _player_item_repo)

#endregion


#
