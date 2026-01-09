class_name BuilderComponent
extends Component

var _player_item_repo: PlayerItemRepo
var BUILDING_SPEED: float = 3.0 ## item/s

enum {IDLE, RUNNING}
var state: int = RUNNING

# Internal IFF Node
var _iff: IFF

var _building_service: BuildingService

# 依賴 BodyComponent 獲取位置
var __body_component: BodyComponent

var team: BitmaskManager.TEAM = BitmaskManager.TEAM.IDLE:
	set(new):
		team = new
		if _iff:
			_iff.team = new

func _on_data_set(data: ComponentData):
	if data is BuilderComponentData:
		team = data.team

func _ready():
	_setup_internal_iff()

func _setup_internal_iff():
	_iff = IFF.new()
	_iff.name = "BuilderIFF"
	_iff.setup(
		team,
		IFF.TARGET.SCAN_ALLY | IFF.TARGET.BE_SCANNED, # Scan allies to build/upgrade
		200.0 # Default detection radius
	)
	add_child(_iff)

func _on_setuped():
	if not __body_component or not __body_component.body:
		printerr("[BuilderComponent] Missing BodyComponent!")
		set_process(false)
		return

func _process(delta: float) -> void:
	# Run on everyone (Server, Owner, Puppet)
	global_position = _get_body_position()
	
	match state:
		IDLE:
			pass
		RUNNING:
			%BuildingEffect.visible = false
			# 這裡原本是重置位置，可能是為了避免畫面殘留?
			%BuildingEffect.global_transform.origin = Vector2.ONE

			if not _iff:
				return

			# 使用 Body 位置進行搜尋
			var current_pos = _get_body_position()

			#print("target: ", _IFF.get_targets())
			for i in _iff.get_sorted_targets(current_pos):
				if not is_instance_valid(i):
					continue
				
				# 優先檢查 New Controller
				if i is BuildingController:
					match i.stage:
						BuildingController.STAGE.PLAN:
							_try_upgrade(i.coord)
							__update_polygon(i)
							break
						BuildingController.STAGE.CONSTRUCT:
							__update_polygon(i, i.breaking)
							if i.breaking:
								_remove(i, delta)
							else:
								_build(i, delta)
							break
					if i.stage != BuildingController.STAGE.COMPLETE:
						break
				

func _get_body_position() -> Vector2:
	if __body_component and __body_component.body:
		return __body_component.body.global_position
	return global_position


func __update_polygon(i: Node, breaking: bool = false):
	if not i.has_method("get_global_points"):
		return
		
	var polygon = i.get_global_points()
	
	# 連線到自己的位置
	polygon.append(_get_body_position())
	
	polygon = Geometry2D.convex_hull(polygon)
	%BuildingEffect.visible = true
	
	%BuildingPolygon.polygon = polygon
	%BuildingPolygon.color = ColorDB.get_building_color(false, breaking)
	%BuildingLine.points = polygon
	%BuildingLine.default_color = ColorDB.get_building_color(true, breaking)


## 建築操作
func _try_upgrade(coord: Vector2i):
	if _building_service:
		_building_service.try_upgrade(coord)
		
func _try_delete(coord: Vector2i):
	if _building_service:
		_building_service.try_delete(coord)


#region move res

## 建造一個建築
func _build(building: Node, dt: float) -> void:
	if not _player_item_repo: return

	# 擁有的資源
	var have: PackedItem = _player_item_repo.contain

	# 原始缺口
	var need: PackedItem = building.get_need_item().sub(building.contain_item) if building.has_method("get_need_item") \
		else building.need_item.sub(building.contain_item)

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
	if not moving.is_zero() and _building_service:
		var coord = building.coord if "coord" in building else building.state.coord
		_building_service.try_transfer_resource(coord, moving, _player_item_repo)

## 移除一個建築
func _remove(building: Node, dt: float) -> void:
	if not _player_item_repo: return

	# 僅保留正值（負值清 0）
	var give_back: PackedItem = building.contain_item.vmax(PackedItem.zero())
	var total_back: float = give_back.vtotal()

	## 無可退 → 完成 (Server 自動 Delete)
	var item_speed := BUILDING_SPEED * dt
	var coord = building.coord if "coord" in building else building.state.coord
	
	if is_zero_approx(total_back):
		if multiplayer.is_server() and building.breaking and _building_service:
			_building_service.try_delete(coord)
		return

	# 依比例限制本 tick 退回總量 cap
	var request: PackedItem = give_back.mul(min(1.0, item_speed / total_back))

	# 逐項保險：夾在 [0, give_back]（避免浮點誤差）
	request = request.vclamp(PackedItem.zero(), give_back)
	
	# Dual Simulation Execution (Direct Call)
	if not request.is_zero() and _building_service:
		var negative_request = PackedItem.zero().sub(request)
		_building_service.try_transfer_resource(coord, negative_request, _player_item_repo)

#endregion
