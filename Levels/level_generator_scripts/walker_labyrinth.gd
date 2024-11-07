extends Node

class_name Walker_labyrinth_room

const DIRECTIONS = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]

var position = Vector2.ZERO
var direction = Vector2.RIGHT
var borders = Rect2()
var step_history = []
var steps_since_turn = 0
var rooms = []
var corridor_width = 2 # Increase for wider corridors

func _init(starting_position, new_border) -> void:
	assert(new_border.has_point(starting_position))
	position = starting_position
	step_history.append(position)
	borders = new_border
	
func walk(steps):
	place_room(position)
	
	for step in steps:
		if steps_since_turn >= 8: # Increase for longer straight sections
			change_direction()
		if step():
			step_history.append(position)
		else:
			change_direction()
	return step_history.reduce(func(accum, item): return accum if item in accum else accum + [item], [])
	
func step() -> bool:
	var target_position = position + direction
	if borders.has_point(target_position):
		steps_since_turn += 1
		position = target_position
		place_wide_corridor(position, direction, corridor_width)
		return true
	return false

func place_wide_corridor(current_position: Vector2, current_direction: Vector2, width: int) -> void:
	for i in range(1, width):
		var side_direction = current_direction.orthogonal().normalized() * i
		var side_tile_1 = current_position + side_direction
		var side_tile_2 = current_position - side_direction
		
		if borders.has_point(side_tile_1):
			step_history.append(side_tile_1)
		if borders.has_point(side_tile_2):
			step_history.append(side_tile_2)

func change_direction():
	place_room(position)
	
	steps_since_turn = 0
	var valid_directions = []
	
	for dir in DIRECTIONS:
		if borders.has_point(position + dir):
			valid_directions.append(dir)
	
	if valid_directions.is_empty():
		return
	
	valid_directions.shuffle()
	direction = valid_directions.front()

func create_room(room_pos, size):
	return {position = room_pos, size = size}
	
func place_room(room_pos: Vector2) -> void:
	var size = Vector2(randi() % 5 + 3, randi() % 5 + 3) # Larger rooms
	var top_left_corner = (room_pos - size / 2).floor()
	if is_too_close(room_pos) or not is_room_within_bounds(top_left_corner, size):
		return
	rooms.append(create_room(room_pos, size))
	mark_room_on_history(top_left_corner, size)

func is_room_within_bounds(top_left_corner: Vector2, size: Vector2) -> bool:
	for y in range(size.y):
		for x in range(size.x):
			var new_step = top_left_corner + Vector2(x, y)
			if not borders.has_point(new_step):
				return false
	return true

func is_too_close(check_pos: Vector2) -> bool:
	for room in rooms:
		if room.position.distance_to(check_pos) < 7: # Increase for more space between rooms
			return true
	return false

func mark_room_on_history(top_left_corner: Vector2, size: Vector2) -> void:
	for y in range(size.y):
		for x in range(size.x):
			var new_step = top_left_corner + Vector2(x, y)
			if borders.has_point(new_step):
				step_history.append(new_step)

func get_end_room():
	var end_room = rooms.pop_back()
	var starting_position = step_history.front()
	
	for room in rooms:
		if starting_position.distance_to(room.position) > starting_position.distance_to(end_room.position):
			end_room = room
	return end_room
