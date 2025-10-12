class_name EscUI
extends Control


var _sound_manager: SoundManager
var _game_controller: GameController

func _ready() -> void:
	DI.register("_esc_ui", self)
	_game_init()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		esc_tab = not esc_tab


func _game_init():
	%TestIcon.visible = false
	_shader_blur = BLUR_MIN





var esc_tab: bool = false:
	set(new):
		esc_tab = new
		if new:
			_open()
		else:
			_close()


func _open():
	visible = true
	_sound_manager.play_ui_sound(OPEN_SOUND)
	_game_controller.stop_game()
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "_shader_blur", BLUR_MAX, BLUR_TIME)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_EXPO)

func _close():
	_sound_manager.play_ui_sound(CLOSE_SOUND)
	_game_controller.continue_game()
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "_shader_blur", BLUR_MIN, BLUR_TIME)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "visible", false, 0.0)





var OPEN_SOUND = preload("uid://b8jibkvtcnj21")
var CLOSE_SOUND = preload("uid://bvqgnmc4vjy8u")

const BLUR_MIN = 0.0
const BLUR_MAX = 3.8
const BLUR_TIME = 0.5
var _shader_blur: float: 
	set(new):
		modulate = Color(1, 1, 1, new/BLUR_MAX)
		_shader_blur = new
		(%Glass.material as ShaderMaterial).set_shader_parameter("blur_amount", new)
























#
