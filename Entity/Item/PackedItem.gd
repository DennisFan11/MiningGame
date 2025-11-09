class_name PackedItem
extends Resource

@export var item_set: Dictionary[Item.ITEM, float] = {}

"""
表示多種資源的組合
用於建築的資源傳遞
"""

func _init() -> void:
	item_set = {}

static func create(items: Dictionary[Item.ITEM, float])-> PackedItem:
	var new_packed_item = PackedItem.new()
	new_packed_item.item_set = items.duplicate(true)
	return new_packed_item

static func create_full()-> PackedItem:
	var item_set: Dictionary[Item.ITEM, float] = {}
	for i in Item.get_all_item():
		item_set[i] = INF
	return create(item_set)
## 數學運算

## 加法：逐項相加
func add(pack: PackedItem) -> PackedItem:
	var new_pack := PackedItem.new()
	new_pack.item_set = item_set.duplicate(true)
	for item in pack.item_set:
		new_pack.item_set[item] = new_pack.item_set.get(item, 0.0) + pack.item_set[item]
	return new_pack


## 減法：逐項相減（允許負值）
func sub(pack: PackedItem) -> PackedItem:
	var new_pack := PackedItem.new()
	new_pack.item_set = item_set.duplicate(true)
	for item in pack.item_set:
		new_pack.item_set[item] = new_pack.item_set.get(item, 0.0) - pack.item_set[item]
	return new_pack


## 乘法：整體倍率（可用於產能倍率）
func mul(i: float) -> PackedItem:
	var new_pack := PackedItem.new()
	new_pack.item_set = {}
	for item in item_set:
		new_pack.item_set[item] = item_set[item] * i
	return new_pack


## 除法：整體除數（允許負數除法，防除零）
func div(i: float) -> PackedItem:
	var new_pack := PackedItem.new()
	new_pack.item_set = {}
	if i == 0:
		push_error("PackedItem.div(): 除數不可為 0")
		return self
	for item in item_set:
		new_pack.item_set[item] = item_set[item] / i
	return new_pack


## 返回每個項目中較小的值
func vmin(pack: PackedItem) -> PackedItem:
	var new_pack := PackedItem.new()
	new_pack.item_set = {}
	
	# 收集所有鍵並去重
	var key_map := {}
	for item in item_set.keys():
		key_map[item] = true
	for item in pack.item_set.keys():
		key_map[item] = true
	
	# 遍歷所有鍵取最小值
	for item in key_map.keys():
		var a = item_set.get(item, 0.0)
		var b = pack.item_set.get(item, 0.0)
		new_pack.item_set[item] = min(a, b)
	
	return new_pack

## 返回每個項目中較大的值
func vmax(pack: PackedItem) -> PackedItem:
	var new_pack := PackedItem.new()
	new_pack.item_set = {}

	# 收集所有鍵（確保雙方都被比較）
	var key_map := {}
	for item in item_set.keys():
		key_map[item] = true
	for item in pack.item_set.keys():
		key_map[item] = true

	for item in key_map.keys():
		var a = item_set.get(item, 0.0)
		var b = pack.item_set.get(item, 0.0)
		new_pack.item_set[item] = max(a, b)

	return new_pack

## 返回每個項目在 min~max 範圍內的結果
func vclamp(min: PackedItem, max: PackedItem) -> PackedItem:
	var new_pack := PackedItem.new()
	new_pack.item_set = {}

	# 收集所有鍵（包含自身、min、max）
	var key_map := {}
	for item in item_set.keys():
		key_map[item] = true
	for item in min.item_set.keys():
		key_map[item] = true
	for item in max.item_set.keys():
		key_map[item] = true

	# 逐項夾限
	for item in key_map.keys():
		var val = item_set.get(item, 0.0)
		var min_val = min.item_set.get(item, -INF)
		var max_val = max.item_set.get(item, INF)
		new_pack.item_set[item] = clamp(val, min_val, max_val)

	return new_pack

## 返回每個項目的絕對值版本
func vabs() -> PackedItem:
	var new_pack := PackedItem.new()
	new_pack.item_set = {}

	for item in item_set.keys():
		new_pack.item_set[item] = abs(item_set[item])

	return new_pack

## 返回所有項目加總
func vtotal() -> float:
	var total := 0.0
	for value in item_set.values():
		total += value
	return total


static func zero()-> PackedItem:
	return create({})



func _to_string() -> String:
	var str = "PackedItem: "
	for id in item_set.keys():
		str += \
		"\n\t" + Item.get_item_name(id) + ":" + str(item_set[id])
	return str

func all_small_than_zero()-> bool:
	for i in item_set.values():
		if i>=0.0:
			return false
	return true

func is_zero()-> bool:
	for i: float in item_set.values():
		if not is_zero_approx(i):
			return false
	return true


func dup_self() -> PackedItem:
	var p := PackedItem.new()
	p.item_set = item_set.duplicate(true)
	return p



#
