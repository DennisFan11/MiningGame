class_name SoundManager
extends Node2D

func _ready() -> void:
	DI.register("_sound_manager", self)



func play_sound( audio_stream: AudioStream, pos: Vector2, l_db: float=1.0):
	var player := AudioStreamPlayer2D.new()
	player.stream = audio_stream
	player.volume_linear = l_db
	player.position = pos
	add_child(player)
	player.play()
	
	player.finished.connect(player.queue_free)

func play_ui_sound( audio_stream: AudioStream, l_db: float=1.0):
	var player := AudioStreamPlayer.new()
	player.stream = audio_stream
	player.volume_linear = l_db
	add_child(player)
	player.play()
	
	player.finished.connect(player.queue_free)










#
