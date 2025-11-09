extends FSM_Mouse

var _game_controller: GameController


func _ready() -> void:
	%BuildingPanel.select_building.connect(_selected)

func _selected(data: BuildingData):
	
	_current_building = data
	
	if _current_icon:
		_current_icon.queue_free()
	_current_icon = Icon.new()
	_current_icon.set_icon(data.get_icon())
	_current_icon.set_color(Icon.COLOR.WHITE)
	_building_manager.add_child(_current_icon)


var _current_building: BuildingData
var _current_icon: Icon
var _building_manager: BuildingManager

func _L_click(): # exec-once
	pass
func _L_clicking():
	pass
func _L_finish(): #exec-once
	if _current_building:
		#_current_building.team = BitmaskManager.TEAM.PLAYER
		var pos = BuildingManager.snap_pos(_building_manager.get_global_mouse_position())
		#print("pos=", pos)
		var plan = _building_manager.try_set_block(
			BuildingManager.global_pos_to_coord(pos),
			_current_building,
			BitmaskManager.TEAM.PLAYER,
			BuildingManager.TYPE.PLAN
		)
		#print("coord=", BuildingManager.global_pos_to_coord(pos))
		#if plan:
			#_game_controller.get_player().add_plan(plan)
	
	
	if _current_icon:
		_current_icon.queue_free()
	_current_building = null

func _Idle(): # 未按下
	if not _current_icon: return 
	var pos = BuildingManager.snap_pos(_building_manager.get_global_mouse_position())
	_current_icon.set_pos(pos)
	#print("pos=", pos)

func _R_click(): # exec-once
	if _current_icon:
		_current_icon.queue_free()
	_current_building = null
func _R_clicking():
	pass
func _R_finish(): #exec-once
	pass
