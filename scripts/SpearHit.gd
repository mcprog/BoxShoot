extends Area2D




func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		body.hurt_me();
	else:
		get_parent().get_parent().set_die()
