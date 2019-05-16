extends Node2D

var Room  = preload("res://Room.tscn")
var font = preload("res://dreamy_land_font.tres")
var Enemy = preload("res://Enemy.tscn")

onready var Map = $TileMap

const tile_size = 16
const tile_scale = 1
const num_rooms = 50
const min_size = 4
const max_size = 10
const h_spread = 400
const cull = .5

const black_tile = 41
const free_tile = 35
const top_edge = 1
const bottom_edge = 18
const left_edge = 15
const right_edge = 20
const corner_lt = 0
const corner_rt = 4
const corner_lb = 17
const corner_rb = 22

const path_r = 23
const path_l = 26

const start_ground = 2

const MAX_ENEMIES = 5

var start_room = null
var end_room = null
const play_mode = true #if we are actually running the game
var player = null
var path #Astar pathfinding object

var enemies

func _ready():
	enemies = get_parent().get_node("Enemies")
	randomize()
	make_rooms()
	
func init():
	if not play_mode:
		return
	
	
	make_map()	
	
	player = get_parent().get_node("Player")
	
	player.position = start_room.position
	update()
	add_child(player)
	

func spawn_enemies(origin):
	for i in randi() % MAX_ENEMIES:
		var enemy = Enemy.instance()
		enemy.global_position = origin
		enemies.add_child(enemy)
				
	
func make_rooms():
	for i in range(num_rooms):
		var pos = Vector2(rand_range(-h_spread, h_spread), 0)
		var room = Room.instance()
		
		var width = min_size + randi() % (max_size - min_size)
		var height = min_size + randi() % (max_size - min_size)
		room.make_room(pos, Vector2(width, height) * tile_size * tile_scale)
		$Rooms.add_child(room)
	yield(get_tree().create_timer(1.1), "timeout")

	var room_positions = []
	var left_most = INF
	var right_most = -INF
	for room in $Rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
			if room.position.x < left_most:
				start_room = room
				left_most = room.position.x
			elif room.position.x > right_most:
				end_room = room
				right_most = room.position.x
			room_positions.append(Vector3(room.position.x, room.position.y, 0))
		
	yield(get_tree(), "idle_frame")
	
	
	#now ready to gen MST
	path = find_mst(room_positions)	
	
	init()

func _draw():
	if start_room:
		draw_string(font, start_room.position-Vector2(225, 0), "start")
	if end_room:
		draw_string(font, end_room.position+Vector2(225, 0), "end")
	
	if play_mode:
		return
		
	
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size * 2),
				Color(32, 228, 0), false)
	if path:
		for p in path.get_points():
			for conn in path.get_point_connections(p):
				var pt_pos = path.get_point_position(p)
				var conn_pos = path.get_point_position(conn)
				draw_line(Vector2(pt_pos.x, pt_pos.y), Vector2(conn_pos.x, conn_pos.y),
						Color(1, 1, 0), 15, true)


func find_mst(nodes):
	var path = AStar.new();
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	while nodes:
		var min_dist = INF
		var min_pos = null
		var pos = null # working position
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			
			for p2 in nodes:
				var dist = p1.distance_to(p2)
				if dist < min_dist:
					min_dist = dist
					min_pos = p2
					pos = p1
					
		var n = path.get_available_point_id()
		path.add_point(n, min_pos)
		path.connect_points(path.get_closest_point(pos), n)
		nodes.erase(min_pos)	
	return path

func make_map():
	
	var corridors = [] #keeps track of which corridors have been generated
	
	
	for room in $Rooms.get_children():
		var sz = (room.size / tile_size).floor()
		var pos = Map.world_to_map(room.position)
		var ul = (room.position / tile_size).floor() - sz

		var y_end = sz.y * 2 - start_ground
		var x_end = sz.x * 2 - start_ground
		
		for y in range(start_ground, y_end):
			if y % 2 == 0:
				Map.set_cell(ul.x + 1, ul.y + y, left_edge)
				Map.set_cell(ul.x + x_end, ul.y + y, right_edge)
			else:
				Map.set_cell(ul.x + 1, ul.y + y, left_edge + 1)
				Map.set_cell(ul.x + x_end, ul.y + y, right_edge + 1)
		for x in range(start_ground, x_end):
			x += ul.x
			var y1 = ul.y + 1
			var y2 = ul.y + y_end
			
			if x % 2 == 0:
				Map.set_cell(x, y1, top_edge + 1)
				Map.set_cell(x, y2, bottom_edge + 1)
			elif x % 4 == 3:
				Map.set_cell(x, y1, top_edge + 2)
				Map.set_cell(x, y2, bottom_edge)
			else:
				Map.set_cell(x, y1, top_edge)
				Map.set_cell(x, y2, bottom_edge)
			
		for x in range(start_ground, x_end): # start at two so the rooms never touch
			for y in range(start_ground, y_end):
				Map.set_cell(ul.x + x, ul.y + y, free_tile)
		Map.set_cell(ul.x + 1, ul.y + 1, corner_lt)
		Map.set_cell(ul.x + (sz.x * 2 - 2), ul.y + 1, corner_rt)
		Map.set_cell(ul.x + 1, ul.y + (sz.y * 2 - 2), corner_lb)
		Map.set_cell(ul.x + (sz.x * 2 - 2), ul.y + (sz.y * 2 - 2), corner_rb)
		if room != start_room and room != end_room:
			spawn_enemies(room.position)
		
		
	for room in $Rooms.get_children():
		#carve connections
		var pt = path.get_closest_point(Vector3(room.position.x, room.position.y, 0))
		for conn in path.get_point_connections(pt): # may be > 1 corridor ber room
			if not conn in corridors:
				var pt_pos = path.get_point_position(pt)
				var start = Map.world_to_map(Vector2(pt_pos.x, pt_pos.y))
				pt_pos = path.get_point_position(conn)
				var end = Map.world_to_map(Vector2(pt_pos.x, pt_pos.y))
				carve_path(start, end)
		corridors.append(pt)	
	

func carve_path(pos1, pos2):
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff =  sign(pos2.y - pos1.y)
	
	if x_diff == 0: x_diff = pow(-1.0, randi() % 2) #raise to -1 power
	if y_diff == 0: y_diff = pow(-1.0, randi() % 2) #raise to -1 power
	
	# need to decide to traverse x/y first
	var x_y = pos1
	var y_x = pos2
	if (randi() % 2) > 0:
		x_y = pos2
		y_x = pos1
	for x in range(pos1.x, pos2.x, x_diff):
		Map.set_cell(x, x_y.y, free_tile)
		Map.set_cell(x, x_y.y + y_diff, free_tile)
		carve_edge_h(x, x_y.y, y_diff)
		
	for y in range(pos1.y, pos2.y, y_diff):
		Map.set_cell(y_x.x, y, free_tile)
		Map.set_cell(y_x.x + x_diff, y, free_tile)
		carve_edge_v(y_x.x, y, x_diff)

func carve_edge_h(x, y, y_diff):
	var top = top_edge
	var bottom = bottom_edge
	
	if x % 2 == 0:
		top += 1
		bottom += 1
	elif x % 4 == 3:
		top += 2
	
	if y_diff == 1:
		if Map.get_cell(x, y - 1) != free_tile:
			Map.set_cell(x, y - 1, top)
		set_bottom_h(x, y + 2, bottom)
	else:
		if Map.get_cell(x, y - 2) != free_tile:
			Map.set_cell(x, y - 2, top)
		set_bottom_h(x, y + 1, bottom)

func set_bottom_h(x, y, bottom):
	var cell = Map.get_cell(x, y)
	if cell == black_tile:
		Map.set_cell(x, y, bottom)
	elif cell == right_edge:
		Map.set_cell(x, y, path_r)
	elif cell == right_edge + 1:
		Map.set_cell(x, y, path_r)
	elif cell == left_edge:
		Map.set_cell(x, y, path_l)
	elif cell == left_edge + 1:
		Map.set_cell(x, y, path_l)
	
func carve_edge_v(x, y, x_diff):
	var left = left_edge
	var right = right_edge
	
	if y % 2 == 0:
		right += 1
		left += 1
	
	if x_diff == 1:
		if Map.get_cell(x - 1, y) == black_tile:
			Map.set_cell(x - 1, y, left)

		if Map.get_cell(x + 2, y) == black_tile:
			Map.set_cell(x + 2, y, right)
	else:
		if Map.get_cell(x - 2, y) == black_tile:
			Map.set_cell(x - 2, y, left)

		if Map.get_cell(x + 1, y) == black_tile:
			Map.set_cell(x + 1, y, right)	



func _process(delta):
	update()


func _input(event):
	if play_mode:
		return
	if event.is_action_pressed("ui_select"):
		for n in $Rooms.get_children():
			n.queue_free()
		path = null
		make_rooms()
	if event.is_action_pressed("ui_focus_next"):
		make_map()