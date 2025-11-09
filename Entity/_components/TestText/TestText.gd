class_name TestText
extends RichTextLabel



func set_label(_text: String):
	self.text = _text
	
func _ready() -> void:
	fit_content = true
	autowrap_mode = TextServer.AUTOWRAP_OFF
