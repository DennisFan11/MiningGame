@abstract
class_name UnitData
extends EntityData

# [重構] 繼承 EntityData 以支援 EntityDB.create_entity

func get_unit_name() -> String:
	return entity_name # 轉發到父類屬性

func get_max_hp() -> float:
	return 100.0

func get_speed() -> float:
	return 200.0

func get_body_polygon() -> PackedVector2Array:
	return PackedVector2Array([])

# 覆蓋父類方法
func get_component_datas() -> Array[ComponentData]:
	return []
