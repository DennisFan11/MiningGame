@abstract
class_name UnitData
extends Resource

func get_unit_name() -> String:
	return ""

func get_max_hp() -> float:
	return 100.0

func get_speed() -> float:
	return 200.0

func get_body_polygon() -> PackedVector2Array:
	return PackedVector2Array([])

func get_component_datas() -> Array[ComponentData]:
	return []
