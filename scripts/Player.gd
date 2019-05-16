extends KinematicBody2D



export var speed = 180

var velocity = Vector2()

const MAX_HEALTH = 8.0
export var health = MAX_HEALTH
var health_delta = 1 / health

func handle_input():
	velocity = Vector2()
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	velocity = velocity.normalized() * speed


func hurt_me():
	health -= 1
	if health <= 0:
		queue_free()
	else:
		$Health.scale.x -= health_delta

func _input(event):
	var z_xy = $Camera2D.zoom.x
	if event.is_action_pressed("zoom_out"):
		z_xy -= .1
	elif event.is_action_pressed("zoom_in"):
		z_xy += .1
	elif event.is_action_pressed("ui_focus_next"):
		hurt_me()
		
	
	z_xy = clamp(z_xy, .1, 1.5)
	$Camera2D.zoom = Vector2(z_xy, z_xy)
	

func _physics_process(delta):
	handle_input()
	velocity = move_and_slide(velocity)