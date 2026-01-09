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

# 建立通用 Unit 的工廠方法
# @param data: UnitData
static func create_unit(data: UnitData) -> Entity:
	# 委派給 EntityDB 進行基礎實體創建
	var unit = EntityDB.create_entity(data)
	return unit

## 創建玩家實體 (包含動態注入 PlayerController)
static func create_player(peer_id: int) -> Entity:
	# 使用靜態註冊的資料
	var data = UnitDB.PLAYER
	
	# 1. 創建基礎 Unit (回傳 Entity)
	var unit = create_unit(data)
	unit.name = str(peer_id)
	
	# 2. 動態注入 PlayerController (不在 PlayerData 中定義)
	ComponentDB.inject_component(unit, ComponentDB.PLAYER_CONTROLLER)
	
	# 3. 注入 PropHolder (手持道具功能)
	ComponentDB.inject_component(unit, ComponentDB.PROP_HOLDER)
	
	# 4. 設定權限 (最後執行，確保所有組件都能繼承)
	unit.set_multiplayer_authority(peer_id)
		
	print("已生成玩家實體 (Entity)")
	return unit
