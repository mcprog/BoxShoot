extends RigidBody2D

var size


func make_room(_pos, _size):
	position = _pos
	size = _size
	var rect = RectangleShape2D.new()
	rect.custom_solver_bias = .75
	rect.extents = size
	$CollisionShape2D.shape = rect

