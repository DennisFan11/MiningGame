class_name TransportLine
extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@onready var base_component: ConveyorComponent = $".."

@onready var in1: InputPort = %InputPort
@onready var in2: InputPort = %InputPort2
@onready var in3: InputPort = %InputPort3

@onready var out1: OutputPort = %OutputPort


var _item_array: Array[LogisticItem] = []

class LogisticItem:
	extends RefCounted
	var type: Item.ITEM
	var dist: float ## 前面的相對距離


const TOTAL_DIST: float = 10.0
const ITEM_SIZE_R: float = 3.0 # 單個物體的半徑
const SPEED: float = 1.0

var _stuck_index: int = 0

func _process(delta: float) -> void:
	_move(delta)
	_input_handle()

func _move(dt: float):
	if _item_array.size() == 0:
		return 
	
	_stuck_index = _index_normalize(_stuck_index)
	var item = _item_array.get(_stuck_index)
	if item.dist < ITEM_SIZE_R:
		_stuck_index = _next_index(_stuck_index)
	
	item = _item_array.get(_stuck_index)
	if item.dist > ITEM_SIZE_R:
		item.dist -= SPEED * dt # 向前縮短距離
	
	
	

func _input_handle():
	var left_space = _get_left_space()
	if left_space <= ITEM_SIZE_R:
		return ## 沒有剩餘空位
	## 要求一個物品
	var item := in1.get_target_line()._output_handle()
	if item:
		item.dist = left_space
		_item_array.push_front(item)
	



## 嘗試從輸入端口獲取 item
func _request_item()-> LogisticItem:
	for _attempt in range(_port_arr.size()):
		var item = __get_next_port().get_target_line()._output_handle()
		if item:
			return item
	return null


## 在目標上執行
func _output_handle()-> LogisticItem:
	if _item_array.size() == 0:
		return null
	## 檢查是否已到達末端 (假設 0 是終點)
	if _item_array.back().dist <= 0.001:
		var item = _item_array.pop_back()
		_set_to_first()
		return item
	return null








# ==============================================================================
# 3. 內部工具
# ==============================================================================



## 獲取剩餘距離
func _get_left_space()-> float:
	var item_dist:float = 0.0
	for i in _item_array:
		item_dist += i.dist
	return TOTAL_DIST-item_dist

## 重置最後指標
func _set_to_first():
	_stuck_index = _item_array.size()-1
	if _item_array.size() == 0:
		return
	_item_array.back().dist += ITEM_SIZE_R


var _port_arr = [
	in1,
	in2, 
	in3
]
var __port_circle_index: int = 0

## Round-robin 要求物品
func __get_next_port()-> InputPort:
	__port_circle_index += 1
	if __port_circle_index >= _port_arr.size():
		__port_circle_index = 0
	return _port_arr[__port_circle_index]


# ==============================================================================
# 4. 無狀態工具
# ==============================================================================



## 正規化 index 防止 null
func _index_normalize(index: int):
	return clampi(index, 0, _item_array.size()-1)

## 從 from_index 數來第一個未阻塞的 item
func _next_index(from_index: int):
	from_index = _index_normalize(from_index)
	for index:int in range(from_index, _item_array.size()):
		if _item_array[index].dist > ITEM_SIZE_R:
			return index
	return _item_array.size()-1
