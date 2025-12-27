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
		ComponentDB.SMALL_UNIT_BODY, # Default Godot Icon, size 32x32
		ComponentDB.VISUAL_SMALL_PLACEHOLDER,
		ComponentDB.UNIT_MOVEMENT,
		HitboxComponentData.new(BitmaskManager.TEAM.PLAYER),
		HealthComponentData.new(get_max_hp()),
		BuilderComponentData.new(BitmaskManager.TEAM.PLAYER),
	]
