extends Node2D

var Arrow = preload("res://Arrow.tscn")

func _input(event):
	if event.is_action_pressed("ui_attack"):
		var mouse_pos = get_global_mouse_position()
		var arrow = Arrow.instance()
		look_at(get_global_mouse_position())
		arrow.rotat = rotation
		arrow.global_position = global_position
		get_parent().get_parent().add_child(arrow)