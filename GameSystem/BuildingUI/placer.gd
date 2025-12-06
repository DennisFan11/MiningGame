extends FSM_Mouse

var _game_controller: GameController
var _building_manager: BuildingManager
var _building_service: BuildingService

var _current_building: BuildingData
var _current_icon: Icon

# 旋轉邏輯簡化
var _dir_types: Array[GridDirs.DIR] = GridDirs.get_dir_types()
var _dir_index: int = 0

func _ready() -> void:
	%BuildingPanel.select_building.connect(_selected)

# ------------------------------------------------------------------------------
# 核心邏輯
# ------------------------------------------------------------------------------

func _selected(data: BuildingData):
	_clear_current_state() # 先清空舊的
	
	_current_building = data
	
	# 建立新 Icon
	_current_icon = Icon.new()
	_current_icon.set_icon(data.get_icon())
	_current_icon.set_color(Icon.COLOR.WHITE)
	_update_icon_rotation()
	_building_manager.add_child(_current_icon)

func _clear_current_state():
	if _current_icon:
		_current_icon.queue_free()
		_current_icon = null
	_current_building = null

func _update_icon_rotation():
	if _current_icon:
		_current_icon.rotation = GridDirs.get_dir_angle(_get_dir())

# ------------------------------------------------------------------------------
# FSM 狀態
# ------------------------------------------------------------------------------

func _Idle(): # 未按下 (每幀執行)
	if not _current_icon: return 
	
	var mouse_pos = _building_manager.get_global_mouse_position()
	var snap_pos = BuildingManager.snap_pos(mouse_pos)
	var coord = BuildingManager.global_pos_to_coord(snap_pos)
	
	_current_icon.set_pos(snap_pos)
	
	var can_build = _building_manager.is_space(coord)
	_current_icon.set_color(Icon.COLOR.WHITE if can_build else Icon.COLOR.RED)

func _L_finish(): # 左鍵放開 (執行一次)
	if not _current_building: return

	var mouse_pos = _building_manager.get_global_mouse_position()
	var coord = BuildingManager.global_pos_to_coord(BuildingManager.snap_pos(mouse_pos))
	
	if _building_manager.is_space(coord):
		_set_plan(coord, _current_building, BitmaskManager.TEAM.PLAYER)
	
	_clear_current_state()

func _R_click(): # 右鍵按下 (取消)
	_clear_current_state()

# ------------------------------------------------------------------------------
# 輸入與輔助
# ------------------------------------------------------------------------------

func _input(event):
	if event.is_action_pressed("R"):
		_dir_index = (_dir_index + 1) % _dir_types.size()
		_update_icon_rotation()
	super(event)

func _get_dir() -> GridDirs.DIR:
	return _dir_types[_dir_index]

# ------------------------------------------------------------------------------
# API 轉接 (保持不變)
# ------------------------------------------------------------------------------

func _set_plan(coord: Vector2i, data: BuildingData, team: BitmaskManager.TEAM):
	_building_service.try_set_plan(
		coord, 
		data, 
		BuildingState.new(coord, team, _get_dir())
	)

# 佔位符函式 (FSM 父類要求)
func _L_click(): pass
func _L_clicking(): pass
func _R_clicking(): pass
func _R_finish(): pass
