extends KinematicBody2D

onready var player = get_parent().get_parent().get_node("Player")

var Spear = preload("res://Spear.tscn")

enum states {
	IDLE,
	WALK,
	RUN,
	AIMLESS
}

enum walks {
	XY,
	YX
}

var state = states.IDLE
var idle_timer = -1
const MIN_IDLE = 1.0
const MAX_IDLE = 7.0

var walk_target
const WALK_TOLERANCE = 10
const WALK_DIST = 150
export var walk_speed = 40
var walk_func = -1

var velocity = Vector2()

var target

var collision_timer = -1
const COLLISION_SLEEP = 1.0
const GROUND = 1
const PLAYER = 2
const PROJECTILE = 4
const ENEMY = 8

export var run_speed = 70
const MAX_HEALTH = 5.0
var health = MAX_HEALTH
var health_delta = 1 / health
const HEAL_TIME = 1.0
var heal_timer = -1
const HURT_SLEEP = 1
var hurt_timer = -1

const SPEAR_SLEEP = 2
var spear_timer = -1

func _ready():
	randomize()
	if get_parent().has_node("Target"):
		target = get_parent().get_node("Target")
	
	
func rand_print(label, string):
	if (randi() % 10 < 1):
		print_debug(label)
		print_debug(string)

func _process(delta):
	if state == states.IDLE:
		if idle_timer > 0:
			idle_timer -= delta
		else:
			state = states.WALK
	elif state == states.WALK:
		if walk_target:
			move_to()
		else:
			walk_target = Vector2(rand_range(-WALK_DIST, WALK_DIST), rand_range(-WALK_DIST, WALK_DIST))
			walk_target += global_position
			if target:
				target.global_position = walk_target
	elif state == states.RUN:
		if spear_timer > 0:
			spear_timer -= delta
		else:
			run()
	elif state == states.AIMLESS:
		pass

func run():
	var spear = Spear.instance()
	spear.from = global_position
	spear.to = player.global_position
	get_parent().add_child(spear)
	spear_timer = SPEAR_SLEEP
	velocity = player.global_position - global_position
	velocity = velocity.normalized() * run_speed
	

func to_idle():
	print_debug("to idle called")
	velocity = Vector2()
	walk_target = null
	idle_timer = rand_range(MIN_IDLE, MAX_IDLE)
	state = states.IDLE

func x_then_y():
	if abs(global_position.x - walk_target.x) > WALK_TOLERANCE:
		velocity.x = sign(walk_target.x - global_position.x)
		velocity.x *= walk_speed
		velocity.y = 0
	elif abs(global_position.y - walk_target.y) > WALK_TOLERANCE:
		velocity.y = sign(walk_target.y - global_position.y)
		velocity.y *= walk_speed
		velocity.x = 0
	else:
		to_idle()

func y_then_x():
	if abs(global_position.y - walk_target.y) > WALK_TOLERANCE:
		velocity.y = sign(walk_target.y - global_position.y)
		velocity.y *= walk_speed
		velocity.x = 0
	elif abs(global_position.x - walk_target.x) > WALK_TOLERANCE:
		velocity.x = sign(walk_target.x - global_position.x)
		velocity.x *= walk_speed
		velocity.y = 0
	else:
		to_idle()

func move_to():
	if walk_func != -1:
		if walk_func == walks.XY:
			x_then_y()
		else:
			y_then_x()
	else:
		var i = randi() % 1
		if i == 0:
			walk_func = walks.XY
		else:
			walk_func = walks.YX

func hurt():
	health -= 1
	if health <= 0:
		queue_free()
	else:
		$Health.scale.x -= health_delta

func heal():
	if health >= MAX_HEALTH:
		return
	health += 1
	$Health.scale.x += health_delta
	heal_timer = HEAL_TIME

func _physics_process(delta):
	var cinfo = move_and_collide(velocity * delta)
	
	if cinfo:
		rand_print("cinfo", cinfo.collider.collision_layer)
		if cinfo.collider.collision_layer == PROJECTILE:
			# need to hurt
			#hurt()
			pass
		elif cinfo.collider.collision_layer == GROUND:
			if collision_timer > 0:
				collision_timer -= delta
			else:
				collision_timer = COLLISION_SLEEP
				walk_target = null
		elif cinfo.collider.collision_layer == PLAYER:
			# need to attack
			if hurt_timer > 0:
				hurt_timer -= delta
			else:
				player.hurt_me()
				hurt_timer = HURT_SLEEP
		elif cinfo.collider.collision_layer == ENEMY:
			# need to handle collison with other enemy
			if heal_timer > 0:
				heal_timer -= delta
			else:
				heal()
		else:
			rand_print("cinfo", cinfo.collider.collision_layer)




