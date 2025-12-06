class_name LineProvider
extends Line2D


"""
# 📄 LineProvider 類別文檔

**類別名稱**：`LineProvider`
**繼承**：`Line2D`
**用途**：擴充 Line2D 功能，提供沿著線條路徑獲取**全域座標 (Global Position)** 的能力。

## 核心方法

### `samp(progress: float) -> Vector2`

計算線條上特定進度的位置，並自動處理座標轉換。

* **參數**：
  * `progress` (`float`)：採樣進度。範圍為 `0.0`（起點）到 `1.0`（終點）。超出範圍的值會被自動限制 (Clamp)。
* **回傳值**：
  * `Vector2`：該位置在世界空間中的**全域座標**。
* **特性**：
  * 考慮了節點自身的 Transform（位移、旋轉、縮放）。
  * 基於線段的實際長度進行線性插值，確保移動速度均勻。
  * 若 `points` 為空，返回節點自身的全域位置。

"""

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
