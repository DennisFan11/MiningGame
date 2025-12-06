class_name LineProvider
extends Line2D


func _ready() -> void:
	visible = Engine.is_editor_hint()

## 根據進度 (0.0 到 1.0) 返回線上的「全域座標」
func samp(progress: float) -> Vector2:
	# 1. 處理空數據情況
	if points.size() == 0:
		return global_position # 沒有點時，返回節點本身的全域原點
	
	if points.size() == 1:
		return to_global(points[0]) # 只有一個點，將其轉為全域並返回

	# 限制 progress 範圍
	progress = clampf(progress, 0.0, 1.0)
	
	# 2. 計算總長度與各段長度 (使用區域座標計算即可)
	var total_length: float = 0.0
	var segment_lengths: Array[float] = []
	
	for i in range(points.size() - 1):
		var dist = points[i].distance_to(points[i+1])
		segment_lengths.append(dist)
		total_length += dist
	
	# 如果長度為 0，返回起點的全域座標
	if total_length <= 0.0:
		return to_global(points[0])
	
	# 3. 尋找目標點的區域座標 (Local Position)
	var target_distance: float = total_length * progress
	var current_distance: float = 0.0
	var local_pos: Vector2 = points[-1] # 預設為最後一點
	
	for i in range(segment_lengths.size()):
		var seg_len = segment_lengths[i]
		
		if current_distance + seg_len >= target_distance:
			if seg_len == 0:
				local_pos = points[i]
			else:
				var t = (target_distance - current_distance) / seg_len
				local_pos = points[i].lerp(points[i+1], t)
			break # 找到後跳出迴圈
			
		current_distance += seg_len
	
	# 4. 關鍵步驟：將區域座標轉換為全域座標
	return to_global(local_pos)
