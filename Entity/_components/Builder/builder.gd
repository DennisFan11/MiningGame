class_name Builder
extends Node2D

var item_source: ItemRepo
var BUILDING_SPEED: float = 3.0 ## item/s

enum {IDLE, RUNNING}
@export var state: int = IDLE

@onready var _IFF = %IFF


var team: BitmaskManager.TEAM = BitmaskManager.TEAM.IDLE:
	set(new):
		team = new
		_IFF.team = new


func _process(delta: float) -> void:
	match state:
		IDLE:
			pass
		RUNNING:
			_running(delta)


## 執行中
func _running(dt: float):
	for i in _IFF.get_targets():
		if i is Building:
			var buildable = i.get_buildable()
			match buildable.state:
				Buildable.STATE.BUILDING:
					_build(buildable, dt)
				Buildable.STATE.REMOVING:
					_remove(buildable, dt)

## 建造一個建築
func _build(building: Buildable, dt: float) -> void:
	# 擁有的資源
	var have: PackedItem = item_source.contain

	# 原始缺口
	var need: PackedItem = building.need_item.sub(building.contain_item)

	# 只取正缺口（負值清為 0）
	var need_pos: PackedItem = need.vmax(PackedItem.zero())
	var need_total: float = need_pos.vtotal()

	# 若無正缺口或吞吐為 0 → 完成或不動作
	var item_speed := BUILDING_SPEED * dt
	if is_zero_approx(need_total):
		building.finished()
		return

	# 計算請求量（不超過存量）
	var request: PackedItem = need_pos.mul(item_speed / need_total)
	var moving: PackedItem = have.vmin(request)

	# 收尾保險：逐項夾在 [0, need_pos] 內，避免浮點誤差
	moving = moving.vclamp(PackedItem.zero(), need_pos)

	item_source.contain = have.sub(moving)
	building.contain_item = building.contain_item.add(moving)


## 移除一個建築（把已投入資源退回倉庫；總量限流 + 依比例）
func _remove(building: Buildable, dt: float) -> void:
	# 僅保留正值（負值清 0）
	var give_back := building.contain_item.vmax(PackedItem.zero())
	var total_back := give_back.vtotal()

	## 無可退 → 完成移除
	var item_speed := BUILDING_SPEED * dt  # 可獨立設置 REMOVE_SPEED
	if is_zero_approx(total_back):
		building.removed()
		return

	# 依比例限制本 tick 退回總量 cap
	var request := give_back.mul(min(1.0, item_speed / total_back))

	# 逐項保險：夾在 [0, give_back]（避免浮點誤差）
	request = request.vclamp(PackedItem.zero(), give_back)

	# 狀態更新
	item_source.contain = item_source.contain.add(request)
	building.contain_item = building.contain_item.sub(request)

	# 若已全部清空，完成移除
	if building.contain_item.vmax(PackedItem.zero()).vtotal() <= 0.0:
		building.removed()


#
