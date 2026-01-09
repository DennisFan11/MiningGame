class_name TestText
extends RichTextLabel



func set_label(_text: String):
	self.text = _text
	
func _ready() -> void:
	add_theme_constant_override("outline_size", 5)
	bbcode_enabled = true
	fit_content = true
	autowrap_mode = TextServer.AUTOWRAP_OFF
