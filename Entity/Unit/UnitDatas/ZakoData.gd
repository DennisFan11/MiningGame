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
		ComponentDB.SMALL_UNIT_BODY,
		ComponentDB.VISUAL_SMALL_PLACEHOLDER,
		ComponentDB.VISION,
		ComponentDB.UNIT_MOVEMENT,
		HitboxComponentData.new(BitmaskManager.TEAM.ENEMY),
		HealthComponentData.new(get_max_hp()),

	]
