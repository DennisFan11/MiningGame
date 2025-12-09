class_name ComponentDB
extends Node

static func inject_component(entity: Entity, data: ComponentData):
	data.inject_to(entity)




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
























#
