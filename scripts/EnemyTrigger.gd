extends Area2D


func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		var enemy = get_parent()
		enemy.state = enemy.states.RUN

func _on_Area2D_body_exited(body):
	var enemy = get_parent()
	enemy.state = enemy.states.AIMLESS
