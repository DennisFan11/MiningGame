extends GutTest

# 測試目標：BuilderComponent
# 測試範圍：
# 1. 在真實場景 (Main.tscn) 中運行
# 2. 自動偵測範圍內的藍圖 (Plan) 並請求升級 (Upgrade)
# 3. 自動偵測範圍內的工地 (Construct) 並請求建造 (Build/Transfer Resource)

var _main_scene: Node2D
var _building_manager: BuildingManager
var _building_service: BuildingService
var _player_item_repo: PlayerItemRepo
var _game_controller: GameController

func before_each():
	# [重要] 集成測試使用真實 Main.tscn 場景
	# 這樣確保所有 Managers (BuildingManager, TerrainManager...) 都與真實遊戲一致
	var main_packed = load("res://Scene/Main/Main.tscn")
	_main_scene = main_packed.instantiate()
	add_child_autofree(_main_scene)
	
	# 等待 _ready 完成
	await get_tree().process_frame
	
	# 透過 DI 或直接從 Main 場景獲取 Managers 引用以便測試 Assert
	# 注意：Main.tscn 中的 Managers 會在 _ready 時自動註冊到 DI
	# 我們可以透過 DI 獲取它們
	# 注意：DI 的變數名稱是 _dependence
	_game_controller = DI._dependence.get("_game_controller")
	_building_manager = DI._dependence.get("_building_manager")
	_building_service = DI._dependence.get("_building_service")
	_player_item_repo = DI._dependence.get("_player_item_repo")

func after_each():
	DI._dependence.clear()

func test_builder_lifecycle():
	# [Setup] 建立真實玩家實體 (透過 UnitDB)
	var peer_id = 1
	var entity = UnitDB.create_player(peer_id)
	# 將玩家加入 Main 場景 (通常是加入 PlayerManager 下的 Spawner 或直接加入，這裡模擬 Server 生成行為)
	# 由於我們沒有透過 Spawner，直接 add_child 即可
	_main_scene.add_child(entity)
	# 必須手動觸發 DI/Setup 因為 add_child 會觸發 _enter_tree -> _ready
	# UnitDB.create_player 已經做過一次 final_setup，但加入 tree 後可能會有其他行為
	
	# 驗證玩家位置 (預設 (0,0))
	entity.global_position = Vector2(100, 100)
	
	# [Verify] 驗證組件存在
	# 使用 get_node_or_null 尋找組件，名稱依據 ComponentDB 定義
	# 通常是 "BuilderComponent" 和 "BodyComponent"
	var builder = _find_component(entity, BuilderComponent)
	var body_comp = _find_component(entity, BodyComponent)
	
	assert_not_null(builder, "玩家實體應包含 BuilderComponent")
	assert_not_null(body_comp, "玩家實體應包含 BodyComponent")
	
	# 確保 Builder 隊伍正確 (預設應為 Player)
	if builder:
		builder.team = BitmaskManager.TEAM.PLAYER
	
	# [Action 1] 放置藍圖 (Plan) 在建造範圍內
	var coord = Vector2i(2, 2) # (128, 128) 附近
	var data_script = load("res://test/integration/resources/DummyBuildingData.gd")
	var state = BuildingState.new(coord, BitmaskManager.TEAM.PLAYER, GridDirs.DIR.UP)
	
	# 使用真實 BuildingService 請求建造
	_building_service.request_build_plan(coord, data_script.resource_path, state.to_dict())
	
	# 確認藍圖生成
	var building = _building_manager.get_block(coord)
	assert_not_null(building, "應生成藍圖")
	
	# 手動調整建築位置以確保在 IFF 範圍內
	building.global_position = Vector2(120, 120)
	
	# 等待 IFF 偵測與 Builder 反應 (Physics Process)
	await wait_seconds(0.5)
	
	# [Assert 1] Builder 應自動升級 Plan -> Construct
	assert_eq(building.stage, BuildingController.STAGE.CONSTRUCT, "Builder 應將 Plan 升級為 Construct")
	
	# [Action 2] 提供資源給 Builder (PlayerRepo)
	_player_item_repo.contain = PackedItem.create({ItemDB.ITEM.IORN: 100})
	
	# 等待建造 Tick
	await wait_seconds(1.0)
	
	# [Assert 2] Builder 應投入資源 (建築內資源 > 0)
	assert_gt(building.contain_item.vtotal(), 0.0, "Builder 應投入資源進入建築")
	
	# [Action 3] 等待建造完成
	await wait_seconds(4.0)
	
	# [Assert 3] 建築應完成
	assert_eq(building.stage, BuildingController.STAGE.COMPLETE, "Builder 應完成建築")

# Helper: 依類型尋找組件 (因為名稱可能變動)
func _find_component(entity: Node, component_type):
	for c in entity.get_children():
		if is_instance_of(c, component_type):
			return c
	return null
