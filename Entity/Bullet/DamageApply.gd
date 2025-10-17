class_name DamageApply
extends Node2D


func get_damage_taker(body: CharacterBody2D)-> DamageTaker:
	#print(body.get_children())
	for i in body.get_children():
		if i is DamageTaker:
			return i
	return null
