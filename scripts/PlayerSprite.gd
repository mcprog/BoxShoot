extends Sprite


var stab_timer = 0
export var stab_time = 1.0

const FRAME_STAB = 18
const FRAME = 17

func _process(delta):
	if stab_timer > 0:
		stab_timer -= delta
	elif frame == FRAME_STAB:
		frame = FRAME
	if Input.is_action_pressed("ui_stab"):
		frame = FRAME_STAB
		stab_timer = stab_time

func _input(event):
	if event.is_action_pressed("ui_left"):
		flip_h = true
	elif event.is_action_pressed("ui_right"):
		flip_h = false