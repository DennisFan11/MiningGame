class_name EntityData
extends Resource

## 基礎實體資料
## 所有 UnitData, BuildingData, PropData 都將繼承此類

@export var entity_name: String = "Entity"

## 獲取該實體所需的所有組件資料
## 子類應覆蓋此方法回傳具體的 ComponentData 列表
func get_component_datas() -> Array[ComponentData]:
	return []
