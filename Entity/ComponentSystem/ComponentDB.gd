class_name ComponentDB
extends Node

static func inject_component(entity: Entity, data: ComponentData):
	data.inject_to(entity)


## 建立 Body 組件資料 (Helper: 通用)
static func create_body_data(shape: Shape2D) -> BodyComponentData:
	return BodyComponentData.new(shape)

## 建立 Body 組件資料 (Helper: 矩形)
static func create_rect_body(width: float, height: float) -> BodyComponentData:
	var shape = RectangleShape2D.new()
	shape.size = Vector2(width, height)
	return create_body_data(shape)

## 建立 Body 組件資料 (Helper: 圓形)
static func create_circle_body(radius: float) -> BodyComponentData:
	var shape = CircleShape2D.new()
	shape.radius = radius
	return create_body_data(shape)


#

static var ICON := IconComponentData.new()


# ==============================================================================
# 1. logistic IO
# ==============================================================================

static var CONVEYOR_LOGISTIC_IO := LogisticIOComponentData.new(
	LogisticIOComponent.CONVEYOR_IN,
	LogisticIOComponent.CONVEYOR_OUT,
)
static var ALL_IN_LOGISTIC_IO := LogisticIOComponentData.new(
	LogisticIOComponent.ALL,
	[]
)
static var ALL_OUT_LOGISTIC_IO := LogisticIOComponentData.new(
	[],
	LogisticIOComponent.ALL
)


# ==============================================================================
# 2. logistic logic
# ==============================================================================

static var CONVEYOR_LOGIC := ConveyorComponentData.new()
static var ITEM_VOID_LOGIC := ItemVoidLogicData.new()

# ==============================================================================
# 3. logistic inventory
# ==============================================================================

static var ITEM_SOURCE := ItemSourceInventoryData.new()
static var TRANSPORT_LINE = TransportLineData.new()

# ==============================================================================
# 4. Common Components (Common 專用組件)
# ==============================================================================

static func HITBOX (p_team) : return HitboxComponentData.new(p_team)
static func BUILDER (p_team) : return BuilderComponentData.new(p_team)

## 生命值組件 (100 hp)
static var HEALTH := HealthComponentData.new(100) 





# ==============================================================================
# 5. Unit Components (Unit 專用組件)
# ==============================================================================

static var UNIT_MOVEMENT := UnitMoveComponentData.new()

## 敵人視野
static var VISION := VisionComponentData.new()

## 玩家控制器
static var PLAYER_CONTROLLER := PlayerControllerComponentData.new()

## 手持道具功能
static var PROP_HOLDER :=  PropHolderComponentData.new()

static var SMALL_SIZE: Vector2 = Vector2(32, 32)

## 顯示組件
static var VISUAL_SMALL_PLACEHOLDER := UnitVisualComponentData.new(null, SMALL_SIZE)

## 碰撞組件
static var SMALL_UNIT_BODY := create_circle_body(SMALL_SIZE.x / 2.0)



# ==============================================================================
# 6. Prop Components (Prop 專用組件)
# ==============================================================================

static var PROP_VISUAL_SMALL := PropVisualComponentData.new(null, SMALL_SIZE)
