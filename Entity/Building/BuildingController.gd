class_name BuildingController
extends Node2D

## Building 控制器
## 管理建築的生命週期、狀態轉換，並持有視覺 Entity

# === 外部耦合（全域 DI 注入）===
var _building_manager: BuildingManager

# === 建築階段 ===
enum STAGE {PLAN, CONSTRUCT, COMPLETE}

# === 核心狀態 ===
var data: BuildingData:
	set(value):
		data = value
		_on_data_changed()

var coord: Vector2i:
	set(value):
		coord = value
		position = BuildingManager.coord_to_global(coord)

var team: BitmaskManager.TEAM = BitmaskManager.TEAM.IDLE:
	set(value):
		team = value
		_update_iff_team()

var dir: GridDirs.DIR = GridDirs.DIR.UP:
	set(value):
		dir = value
		rotation = GridDirs.get_dir_angle(dir)

var stage: STAGE = STAGE.PLAN:
	set(value):
		var old_stage = stage
		stage = value
		if old_stage != stage:
			_on_stage_changed()

var breaking: bool = false:
	set(value):
		breaking = value
		_on_breaking_changed()

var contain_item: PackedItem = PackedItem.new()

# === IFF 組件（透過 LocalInjector 或直接持有）===
var _iff: IFF

# === 視覺 Entity ===
var _visual_entity: Entity

signal progress_changed(progress: float)
signal breaking_changed(breaking: bool)

# ==============================================================================
# 生命週期
# ==============================================================================

func _ready():
	_setup_iff()
	_rebuild_visual_entity() # 確保初始視覺正確
	_setup_multiplayer_sync()

func _on_injected():
	if _building_manager:
		_building_manager.register_building(self)

func _setup_multiplayer_sync():
	var sync = NetworkSynchronizer.new()
	sync.name = "Synchronizer"
	sync.set_multiplayer_authority(1) # Server Authority
	
	sync.add_property(NodePath(":stage"))
	sync.add_property(NodePath(":breaking"))
	# coord, team, data 通常在 spawn 時確定，或極少變更
	# 如果 team 會變（佔領），也需要 sync
	sync.add_property(NodePath(":team"))
	
	add_child(sync )
	
	if not multiplayer.is_server():
		sync.start()


# ==============================================================================
# 建築資源計算
# ==============================================================================

func get_need_item() -> PackedItem:
	if data:
		return data.get_need_item()
	return PackedItem.new()

func get_progress() -> float:
	return _progress

func update_progress():
	# 計算進度供視覺更新
	var need = get_need_item()
	var total = need.vtotal()
	if total > 0:
		_progress = contain_item.vtotal() / total
	else:
		_progress = 1.0
	_update_visual_progress()

func is_building_finish() -> bool:
	return get_need_item().sub(contain_item).is_zero()

func is_remove_finish() -> bool:
	return breaking and contain_item.is_zero()

# ==============================================================================
# 座標與幾何
# ==============================================================================

func get_global_rect() -> Rect2:
	var block_size = BuildingManager.BLOCK_SIZE
	var pos = BuildingManager.coord_to_global(coord)
	return Rect2(
		pos - block_size / 2.0,
		block_size
	)

func get_global_points() -> PackedVector2Array:
	var rect = get_global_rect()
	return PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y)
	])

# ==============================================================================
# 內部方法
# ==============================================================================

var _progress: float = 0.0:
	set(value):
		if _progress != value:
			_progress = value
			progress_changed.emit(_progress)

func _setup_iff():
	_iff = IFF.new()
	_iff.name = "IFF"
	_iff.target = IFF.TARGET.BE_SCANNED | IFF.TARGET.SCAN_ALLY
	_iff.radius = 64.0
	add_child(_iff)
	_update_iff_team()

func _update_iff_team():
	if _iff:
		_iff.team = team

func _on_data_changed():
	# 資料變更時更新視覺
	# 無論是否有舊的 Entity，都嘗試重建（因為可能是第一次設定 Data）
	_rebuild_visual_entity()

func _on_stage_changed():
	# 階段變更時重建視覺 Entity
	_rebuild_visual_entity()

func _on_breaking_changed():
	# 拆除狀態變更
	breaking_changed.emit(breaking)
	_update_visual_breaking()

# 建立 Entity 容器的輔助方法

func _rebuild_visual_entity():
	# 清理舊 Entity
	if _visual_entity:
		_visual_entity.name = "VisualEntity_Freeing" # 避免名稱衝突
		_visual_entity.queue_free()
		_visual_entity = null
	
	# 如果沒有 Data，無法建立視覺
	if not data:
		return
	
	# Use EntityDB to create visual
	_visual_entity = EntityDB.create_building_visual(stage, data, self)
	_visual_entity.name = "VisualEntity"
	add_child(_visual_entity)
	
	# Inject Controller dependency (Redundant but harmless if registered above, but safer to keep consistency)
	# _visual_entity.__loca_injector.register("__building_controller", self)
	
	# Manually trigger injection/setup for components that might need the controller immediately
	# But Components usually wait for _ready or _setuped.
	# Since we just added it to tree, _ready will run. 
	# LocalInjector dependencies registered above will be available in _on_injected/_on_setuped.

func _update_visual_progress():
	# 已透過信號處理
	pass

func _update_visual_breaking():
	# 已透過信號處理
	pass
