extends KinematicBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var rotat = 0.0
export var speed = 50

var velocity = Vector2(1, 0)

func _ready():
	rotation = rotat
	
	velocity = velocity.rotated(rotation)




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	var cinfo = move_and_collide(velocity * speed * delta)
	if cinfo:
		if cinfo.collider.collision_layer == 8:
			cinfo.collider.hurt()
		queue_free()
