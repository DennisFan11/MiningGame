class_name DebugUI
extends Control





func _ready() -> void:
	DI.register("_debug_ui", self)




func _process(delta: float) -> void:
	%FPSLabel.text = "[color=green][font_size=20]  Fps: {0}".format(
		[
			Performance.get_monitor(Performance.TIME_FPS)
		]
	)
