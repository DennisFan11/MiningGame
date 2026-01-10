class_name PropData
extends EntityData

# Properties for Editor/Inspector (Optional, can be used to init fields)
@export var icon: Texture
@export var mass: float = 1.0


# Virtual Methods (Defaults)
func get_entity_name() -> String:
	return "Prop"

func get_icon() -> Texture:
	return icon # Fallback to export if set

func get_mass() -> float:
	return 1.0

func get_shape(radius: float) -> Shape2D:
	var s = CircleShape2D.new()
	s.radius = radius
	return s

# 獲取該實體所需的所有組件資料 (Override from EntityData)
func get_component_datas() -> Array[ComponentData]:
	return []

# Context-Specific Component Access
# ==============================================================================

func get_world_component_datas() -> Array[ComponentData]:
	return [
		ComponentDB.PROP_VISUAL_SMALL,
		PropBodyComponentData.new(get_shape(30.0), get_mass()),
	]

func get_held_component_datas() -> Array[ComponentData]:
	# Held prop doesn't need body (physics), just visual
	return [
		#ComponentDB.PROP_VISUAL_SMALL,
	]
