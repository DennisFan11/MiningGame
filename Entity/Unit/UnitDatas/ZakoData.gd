class_name ZakoData
extends UnitData

func get_unit_name() -> String:
	return "Zako"

func get_max_hp() -> float:
	return 50.0

func get_speed() -> float:
	return 150.0

func get_component_datas() -> Array[ComponentData]:
	return [
		ComponentDB.create_rect_body(24, 24),
		HitboxComponentData.new(BitmaskManager.TEAM.ENEMY),
		ComponentDB.UNIT_MOVEMENT,
		HealthComponentData.new(get_max_hp()),
		ComponentDB.VISION,
	]
