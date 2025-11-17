class_name ParticleManager
extends Node2D

func _ready() -> void:
	DI.register("_particle_manager", self)




enum TYPE {SPARK}
var map: Dictionary[TYPE,PackedScene] = {
	TYPE.SPARK : preload("uid://bwcvoi3mre6yq")
}

func create(type: TYPE, global_pos: Vector2, angle: float, auto_free: bool=true)-> GPUParticles2D:
	var node: GPUParticles2D = map[type].instantiate()
	node.global_position = global_pos
	node.rotation = angle
	node.emitting = true
	if auto_free:
		node.finished.connect(node.queue_free)
	add_child(node)
	return node
