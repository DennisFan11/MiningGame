class_name DebugDraw
extends Node2D





func _ready() -> void:
	DI.register("_debug_draw", self)


const FONT = preload("uid://1kh3hjn0q4xj")


func d_draw_line(from:Vector2, to:Vector2, color:Color=Color.WHITE, width:float=3.0, time:float=0.1):
	_add_draw(func():
		self.draw_line(from, to, color, width),
		time
	)






## add_draw 用於暫時註冊一個繪製指令（Callable），可在指定時間內於 _draw() 階段持續顯示除錯圖形並自動移除。
func _add_draw(callable: Callable, time: float=1.0):
	_draw_id += 1
	_draw_map[_draw_id] = callable
	
	## 時間到後自動釋放
	var timer := get_tree().create_timer(time)
	timer.timeout.connect(
		_free_draw.bind(_draw_id)
	)










signal draw_finish


## NOTE 內部邏輯

func _free_draw(draw_id: int):
	await draw_finish
	_draw_map.erase(draw_id)

func _process(delta: float) -> void:
	queue_redraw()

var _draw_id:int = 0
var _draw_map: Dictionary[int, Callable] = {}
func _draw() -> void:
	#print("Debug draw start")
	for i: Callable in _draw_map.values():
		i.call()
	draw_finish.emit()
		#print("Draw")
