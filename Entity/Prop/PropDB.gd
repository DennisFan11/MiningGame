class_name PropDB
extends Node

# Preload Data Definitions
const StoneDataScript = preload("res://Entity/Prop/Definitions/StoneData.gd")
const SwordDataScript = preload("res://Entity/Prop/Definitions/SwordData.gd")

# Enums
enum PROP {
	STONE,
	SWORD
}

# Registry
static var props: Dictionary[int, PropData] = {}

# ==============================================================================
# Factory Facade (Explicit State Creation)
# ==============================================================================

static func create_world_prop(data: PropData, pos: Vector2, force: Vector2) -> Entity:
	# 1. Create State (No flags, just physical properties)
	var state = PropState.new(pos, Vector2.ONE, force)
	
	# 2. Instantiate Entity (Data/State injection via EntityDB)
	var entity = EntityDB.create_entity(data, state)
	
	# 3. Inject WORLD Components (Visual + Body)
	# NOTE: We manually inject components because we split World/Held data in PropData
	var components = data.get_world_component_datas()
	for comp in components:
		ComponentDB.inject_component(entity, comp)
		
	return entity

static func create_held_prop(data: PropData) -> Entity:
	# 1. Create State (Held Transform)
	var state = PropState.new(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	
	# 2. Instantiate Entity
	var entity = EntityDB.create_entity(data, state)
	
	# 3. Inject HELD Components (Visual Only)
	var components = data.get_held_component_datas()
	for comp in components:
		ComponentDB.inject_component(entity, comp)
	
	# 4. Apply Initial Transform (Since manual transform control component is absent in Held mode)
	if entity:
		entity.position = state.position
		entity.scale = state.scale
		
	return entity

# ==============================================================================
# Data Access
# ==============================================================================

static func get_data(id: int) -> PropData:
	if props.is_empty():
		_static_init()
	return props.get(id)

# ==============================================================================
# Initialization & Registration
# ==============================================================================

static func _static_init():
	_register(PROP.STONE, StoneDataScript.new())
	_register(PROP.SWORD, SwordDataScript.new())

static func _register(id: PROP, data: PropData):
	props[id] = data
