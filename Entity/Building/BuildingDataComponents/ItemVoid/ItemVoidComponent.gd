class_name ItemVoidComponent
extends LogisticComponent








@onready
var inputs:Array[InputPort]= [
	%InputPort,
	%InputPort2,
	%InputPort3,
	%InputPort4
]

func _process(delta: float) -> void:
	for i: InputPort in inputs:
		if i.from_line:
			var item: LineItem = i.from_line.try_take_item()
