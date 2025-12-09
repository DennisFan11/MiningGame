class_name LogisticIOComponentData
extends ComponentData



func get_component()-> Component:
	return LogisticIOComponent.new()

func get_property()-> String:
	return "__logistic_io_component"

func _init(
		_input_port: Array[Vector2i], _output_port: Array[Vector2i]
	) -> void:
	self.input_port = _input_port
	self.output_port = _output_port

var input_port: Array[Vector2i]
var output_port: Array[Vector2i]
