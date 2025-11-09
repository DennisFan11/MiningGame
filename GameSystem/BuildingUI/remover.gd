extends FSM_Mouse




var first_pos: Vector2 = Vector2.ZERO
var second_pos: Vector2 = Vector2.ZERO

var _building_manager: BuildingManager





func _L_click(): # exec-once
	pass
func _L_clicking():
	pass
func _L_finish(): #exec-once
	pass

func _Idle(): # 未按下
	pass





func _R_click(): # exec-once
	visible = true
	first_pos = _building_manager.get_global_mouse_position()
	second_pos = _building_manager.get_global_mouse_position()
	_update_points()
func _R_clicking():
	second_pos = _building_manager.get_global_mouse_position()
	_update_points()
func _R_finish(): #exec-once
	visible = false








func _update_points() -> void:
	# 用 abs() 自動把 size 轉成正值並修正 position
	var rect := Rect2(first_pos, second_pos - first_pos).abs()

	# 若有格點吸附，先處理
	var v1 = _building_manager.floor_pos(rect.position)
	var v2 = _building_manager.ceil_pos(rect.position+ rect.size)

	# 產生四點
	var pts := rect2_to_chamfered_points(Rect2(v1, v2-v1))

	# Line2D 如果沒設 closed=true，就補上起點以封口；有設 closed 則直接給四點即可
	%RemovePolygon.polygon = pts

	var open := PackedVector2Array(pts)
	%RemoveLine.points = open
	




# 將 Rect2 轉成四角 45° 倒角（邊長=chamfer）的多邊形點列
func rect2_to_chamfered_points(rect: Rect2, chamfer: float = 15.0) -> PackedVector2Array:
	var w := rect.size.x
	var h := rect.size.y
	# 倒角邊長不能超過寬/高的一半
	var c = min(chamfer, min(w * 0.5, h * 0.5))

	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := x0 + w
	var y1 := y0 + h

	# 順時針：從上邊左倒角點開始
	return PackedVector2Array([
		Vector2(x0 + c, y0),   # 上邊，離左上 c
		Vector2(x1 - c, y0),   # 上邊，離右上 c
		Vector2(x1, y0 + c),   # 右上倒角端點
		Vector2(x1, y1 - c),   # 右邊，離右下 c
		Vector2(x1 - c, y1),   # 右下倒角端點
		Vector2(x0 + c, y1),   # 下邊，離左下 c
		Vector2(x0, y1 - c),   # 左下倒角端點
		Vector2(x0, y0 + c)    # 左邊，離左上 c
	])


#
