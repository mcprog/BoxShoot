extends Path2D


export var to = Vector2()
export var from =  Vector2()
export var speed = 190

const DIE_TIME = 5.0
var die_timer = -1.0;
var die = false

func _ready():
	var curve = Curve2D.new()
	var diff_to = to - from
	if diff_to.y > 0:
		curve.add_point(from, Vector2(), Vector2(diff_to.x, 0))
	else:
		curve.add_point(from, Vector2(), Vector2(0, diff_to.y))
	curve.add_point(to)
	set_curve(curve)

func set_die():
	die_timer = DIE_TIME
	die = true
	$PathFollow2D/Area2D/CollisionShape2D.disabled = true

func _process(delta):
	if die:
		if die_timer > 0:
			die_timer -= delta
		else:
			queue_free()
		return
	elif $PathFollow2D.unit_offset >= 1:
		set_die()
		return
	
	$PathFollow2D.offset += (delta * speed)
	

