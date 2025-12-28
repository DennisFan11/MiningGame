class_name UnitDB
extends Node

# ==============================================================================
# Unit Data Registration (ComponentDB Style)
# ==============================================================================

static var PLAYER := PlayerData.new()
static var ZAKO := ZakoData.new()

# ==============================================================================
# Factory Methods
# ==============================================================================

# Factory method to create a generic unit
static func create_unit(data: UnitData, state: UnitState) -> UnitEntity:
	# Load a generic base scene for Units. 
	var scene_path = "res://Entity/Unit/UnitEntity.tscn" # Hypothetical base scene
	if data.get("scene_path"): # If Data carries scene path
		scene_path = data.scene_path
		
	var node
	if ResourceLoader.exists(scene_path):
		node = load(scene_path).instantiate()
	else:
		# Fallback: Create script instance (might lack Node structure)
		node = UnitEntity.new()
		node.name = "Unit"
	
	node.data = data
	
	# Inject components
	for component_data in data.get_component_datas():
		ComponentDB.inject_component(node, component_data)
		
	# Assign State last (triggering injection updates)
	node.state = state
	
	node.final_setup()
	return node

## 創建玩家實體 (包含動態注入 PlayerController)
static func create_player(peer_id: int) -> UnitEntity:
	# 使用靜態註冊的資料
	var data = UnitDB.PLAYER
	
	var state = UnitState.new()
	state.team = BitmaskManager.TEAM.PLAYER
	
	# 1. 創建基礎 Unit
	var unit = create_unit(data, state)
	unit.name = str(peer_id)
	unit.set_multiplayer_authority(peer_id)
	
	# 2. 動態注入 PlayerController (不在 PlayerData 中定義)
	ComponentDB.inject_component(unit, ComponentDB.PLAYER_CONTROLLER)
	
	# 3. 注入 PropHolder (手持道具功能)
	ComponentDB.inject_component(unit, ComponentDB.PROP_HOLDER)
		
	print("Player Spawnned")
	return unit
