class_name DummyBuildingDataFlow
extends BuildingData

func get_building_name() -> String: return "DummyFlow"
func get_description() -> String: return "DescFlow"
func get_icon(): return PlaceholderTexture2D.new()
func get_need_item(): return PackedItem.create({ItemDB.ITEM.IORN: 10})
func get_component_datas(): return []
