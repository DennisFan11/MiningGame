@abstract
class_name Port
extends Component




func get_building()-> Building: 
	return _building


var _building: Building
var _logistic_manager: LogisticManager

func _entity_ready(entity: Entity):
	assert(entity is Building, "Entity is not Building")
	_building = (entity as Building)
	_logistic_manager.register(_building.get_coord(), self)
	
func _exit_tree() -> void:
	_logistic_manager.unregister(_building.get_coord(), self)
