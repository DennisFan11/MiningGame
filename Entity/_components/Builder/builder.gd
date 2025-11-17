class_name Builder
extends Node2D

var _player_item_repo: PlayerItemRepo
var BUILDING_SPEED: float = 3.0 ## item/s

enum {IDLE, RUNNING}
var state: int = RUNNING

@onready var _IFF = %IFF

var _building_manager: BuildingManager

var team: BitmaskManager.TEAM = BitmaskManager.TEAM.IDLE:
	set(new):
		team = new
		_IFF.team = new

#var _building_plan_queue: Array[BuildingPlan] = []



func _process(delta: float) -> void:
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
					_convert_plan(i)
					_update_polygon(i)
					break
				if i is BuildingConstruct:
					_update_polygon(i, i.breaking)
					if i.breaking:
						_remove(i, delta)
						break
					else:
						_build(i, delta)
						break



func _update_polygon(i: BuildingI, breaking: bool=false):
	
	var polygon = i.get_global_points()
	polygon.append(global_position)
	polygon = Geometry2D.convex_hull(polygon)
	%BuildingEffect.visible = true
	
	%BuildingPolygon.polygon = polygon
	%BuildingPolygon.color = ColorDB.get_building_color(false, breaking)
	%BuildingLine.points = polygon
	%BuildingLine.default_color = ColorDB.get_building_color(true, breaking)
	if i is BuildingConstruct:
		i.set_breaking_color(breaking)



## 把藍圖轉換成施工建築
func _convert_plan(plan: BuildingPlan):
	
	var data = plan.get_data()
	var block = _building_manager.get_block(plan.coord)
	if block and block != plan:
		print_rich("[color=red]Building Convert Faild at:", plan.coord)
		return
	else:
		print("convert" + str(plan))
		_building_manager.set_block(
			plan.coord,
			data,
			plan.team,
			BuildingManager.TYPE.CONSTRUCT
		)
		
func _convert_construct(construct: BuildingConstruct):
	var data = construct.get_data()
	var block = _building_manager.get_block(construct.coord)
	if block and block != construct:
		print_rich("[color=red]Building Convert Faild at:", construct.coord)
		return
	else:
		print("convert" + str(construct))
		_building_manager.set_block(
			construct.coord,
			data,
			construct.team,
			BuildingManager.TYPE.BUILDING
		)
	
func _remove_construct(construct: BuildingConstruct):
	_building_manager.delete_block(construct.coord)
	#construct.queue_free()


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

	# 若無正缺口或吞吐為 0 → 完成或不動作
	var item_speed := BUILDING_SPEED * dt
	if is_zero_approx(need_total):
		_convert_construct(building)
		return

	# 計算請求量（不超過存量）
	var request: PackedItem = need_pos.mul(item_speed / need_total)
	var moving: PackedItem = have.vmin(request)

	# 收尾保險：逐項夾在 [0, need_pos] 內，避免浮點誤差
	moving = moving.vclamp(PackedItem.zero(), need_pos)

	_player_item_repo.contain = have.sub(moving)
	building.contain_item = building.contain_item.add(moving)
	
	building.progress = building.contain_item.vtotal() /  building.need_item.vtotal()

## 移除一個建築（把已投入資源退回倉庫；總量限流 + 依比例）
func _remove(building: BuildingConstruct, dt: float) -> void:
	# 僅保留正值（負值清 0）
	var give_back := building.contain_item.vmax(PackedItem.zero())
	var total_back := give_back.vtotal()

	## 無可退 → 完成移除
	var item_speed := BUILDING_SPEED * dt  # 可獨立設置 REMOVE_SPEED
	if is_zero_approx(total_back):
		_remove_construct(building)
		return

	# 依比例限制本 tick 退回總量 cap
	var request := give_back.mul(min(1.0, item_speed / total_back))

	# 逐項保險：夾在 [0, give_back]（避免浮點誤差）
	request = request.vclamp(PackedItem.zero(), give_back)

	# 狀態更新
	_player_item_repo.contain = _player_item_repo.contain.add(request)
	building.contain_item = building.contain_item.sub(request)

	# 若已全部清空，完成移除
	if building.contain_item.vmax(PackedItem.zero()).vtotal() <= 0.0:
		_remove_construct(building)
		return 
	
	building.progress = building.contain_item.vtotal() /  building.need_item.vtotal()







#endregion


#
