class_name PlayerData
extends UnitData

func get_unit_name() -> String:
	return "Player"

func get_max_hp() -> float:
	return 100.0

func get_speed() -> float:
	return 600.0

func get_component_datas() -> Array[ComponentData]:
	return [
		UnitVisualComponentData.new(null), # Default Godot Icon
		ComponentDB.create_rect_body(32, 32),
		HitboxComponentData.new(BitmaskManager.TEAM.PLAYER),
		ComponentDB.UNIT_MOVEMENT,
		HealthComponentData.new(get_max_hp()),
	]
