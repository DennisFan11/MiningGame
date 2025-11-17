class_name ColorDB
extends Node








static func get_building_color(
	outline: bool, breaking: bool
	)-> Color:
	match [outline, breaking]:
		[false, true]:
			return Color("ff424268")
		[true, true]:
			return Color("ff4242dc")
		[true, false]:
			return Color("ffbf0ce2")
		[false, false]:
			return Color("ff910ca8")
	return Color.MEDIUM_PURPLE
