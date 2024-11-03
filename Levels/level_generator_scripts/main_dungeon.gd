extends Node2D

var walker
var map
var ground_layer = 0
var rooms = []
const min_distance_from_player = 5

@onready var player_scene = preload("res://Entities/Scenes/Player/player.tscn")
@onready var exit_scene = preload("res://Interactables/Scenes/exit_portal.tscn")
@onready var next_level_scene = preload("res://Interactables/Scenes/next_level.tscn")
@onready var enemy_scene = preload("res://Entities/Scenes/Enemies/enemy_1.tscn")
@onready var enemy_2_scene = preload("res://Entities/Scenes/Enemies/enemy_2.tscn")
@onready var boss_1 = preload("res://Entities/Scenes/Enemies/shooter_enemy.tscn")
@onready var health_pickup_scene = preload("res://Interactables/Scenes/health_pickup.tscn")
@onready var double_damage_pickup_scene = preload("res://Interactables/Scenes/double_damage_pickup.tscn")
@onready var double_speed_pickup_scene = preload("res://Interactables/Scenes/double_speed_pickup.tscn")
@onready var double_defense_pickup_scene = preload("res://Interactables/Scenes/double_defense_pickup_scene.tscn")
@onready var tilemap = $Tiles/TileMap

@export var borders = Rect2(1, 1, 70, 50)

func _ready() -> void:
	# Called when the scene is ready, sets up the level, plays music
	randomize()
	generate_level()
	if not MusicDungeon.is_playing_level_music:
		MusicDungeon.play_music_level()
	MusicMainLevel.stop()
	
func _input(event: InputEvent) -> void:
	# Detects input events, restarts level if necessary
	if Input.is_action_just_pressed("restart_level"):
		get_tree().reload_current_scene()

func generate_level() -> void:
	# Generates the entire level including map, player, enemies, and pickups
	walker = Walker_room.new(Vector2(25,25), borders)
	map = walker.walk(700)
	clear_and_set_tiles()
	instance_player()
	instance_portal()
	create_navigation()
	instance_enemies()
	instance_shooter_enemy()
	instance_health_pickup()
	instance_random_powerup()

func create_navigation():
	# Creates the navigation region for pathfinding using the map outline
	var navigation_region = NavigationRegion2D.new()
	add_child(navigation_region)
	
	var navigation_polygon = NavigationPolygon.new()
	var outline = PackedVector2Array()
	
	for cell in map:
		outline.append(Vector2(cell.x * 16, cell.y * 16))
	
	outline = Geometry2D.convex_hull(outline)
	
	navigation_polygon.add_outline(outline)
	navigation_polygon.make_polygons_from_outlines()
	navigation_region.navigation_polygon = navigation_polygon
	
func instance_random_powerup() -> void:
	var powerups = [
		{"name": "double_defense", "weight": 30},
		{"name": "double_speed", "weight": 10},
		{"name": "double_damage", "weight": 20}
	]
	
	var total_weight = 0
	for powerup in powerups:
		total_weight += powerup.weight
	
	var random_value = randf() * total_weight
	var current_weight = 0
	var chosen_powerup = ""
	
	for powerup in powerups:
		current_weight += powerup.weight
		if random_value <= current_weight:
			chosen_powerup = powerup.name
			break
	
	match chosen_powerup:
		"double_defense":
			instance_double_defense_pickup()
		"double_speed":
			instance_double_speed_pickup()
		"double_damage":
			instance_double_damage_pickup()
			
func instance_specific_pickup(pickup_scene: PackedScene) -> void:
	var player_node = get_node("Player")
	if not player_node:
		return
	var player_position = tilemap.local_to_map(player_node.position)
	var attempts = 0
	var max_attempts = 100
	var pickup_spawned = false
	
	while not pickup_spawned and attempts < max_attempts:
		var random_position = map[randi() % len(map)]
		var world_position = tilemap.map_to_local(random_position)
		
		if random_position.distance_to(player_position) >= min_distance_from_player and not is_tile_occupied(world_position):
			var pickup = pickup_scene.instantiate()
			pickup.position = world_position
			add_child(pickup)
			pickup_spawned = true
		
		attempts += 1

func instance_double_defense_pickup() -> void:
	instance_specific_pickup(double_defense_pickup_scene)

func instance_double_speed_pickup() -> void:
	instance_specific_pickup(double_speed_pickup_scene)

func instance_double_damage_pickup() -> void:
	instance_specific_pickup(double_damage_pickup_scene)

func instance_health_pickup() -> void:
	# Instantiates health pickups at random valid locations on the map
	var player_node = get_node("Player")
	if not player_node:
		return

	var player_position = tilemap.local_to_map(player_node.position)
	var attempts = 0
	var max_attempts = 100
	var health_pickup_spawned = false
	
	while not health_pickup_spawned and attempts < max_attempts:
		var random_position = map[randi() % len(map)]
		var world_position = tilemap.map_to_local(random_position)
		
		if random_position.distance_to(player_position) >= min_distance_from_player and not is_tile_occupied(world_position):
			var health_pickup = health_pickup_scene.instantiate()
			health_pickup.position = world_position
			add_child(health_pickup)
			health_pickup_spawned = true
		
		attempts += 1

func clear_and_set_tiles() -> void:
	# Clears the existing tiles and sets the new tiles based on the map
	var using_cells: Array = []
	var all_cells: Array = tilemap.get_used_cells(ground_layer)
	tilemap.clear()
	walker.queue_free()

	for tile in all_cells:
		if !map.has(Vector2(tile.x, tile.y)):
			using_cells.append(tile)
			
	tilemap.set_cells_terrain_connect(ground_layer, using_cells, ground_layer, ground_layer, false)
	tilemap.set_cells_terrain_path(ground_layer, using_cells, ground_layer, ground_layer, false)

func instance_player():
	# Instantiates the player at the starting position
	var player = player_scene.instantiate()
	add_child(player)
	player.position = map.pop_front() * 16

func instance_portal():
	# Instantiates the exit and next-level portals at different locations
	var exit_portal = exit_scene.instantiate()
	var next_level_portal = next_level_scene.instantiate()
	
	add_child(exit_portal)
	add_child(next_level_portal)
	
	var end_room_position = walker.get_end_room().position * 16
	var other_position = get_other_portal_position(end_room_position)
	
	exit_portal.position = end_room_position
	next_level_portal.position = other_position

func get_other_portal_position(existing_position):
	# Finds a valid position for the other portal at a distance from the existing one
	var attempts = 0
	var max_attempts = 100
	var min_distance = 160
	
	while attempts < max_attempts:
		var random_position = map[randi() % len(map)] * 16
		if random_position.distance_to(existing_position) >= min_distance:
			return random_position
		attempts += 1
	
	return map[randi() % len(map)] * 16
	
func instance_shooter_enemy() -> void:
	var player_node = get_node("Player")
	if not player_node:
		return
	var player_position = tilemap.local_to_map(player_node.position)
	var attempts = 0
	var max_attempts = 500
	var enemies_spawned = 0
	
	var total_enemies_to_spawn = randi_range(5, 7)
	while enemies_spawned < total_enemies_to_spawn and attempts < max_attempts:
		var random_position = map[randi() % len(map)]
		var world_position = tilemap.map_to_local(random_position)
		
		if random_position.distance_to(player_position) >= min_distance_from_player:
			var enemy = boss_1.instantiate()
			
			var nav_agent = NavigationAgent2D.new()
			enemy.add_child(nav_agent)
			
			enemy.base_speed = randf_range(90, 130)
			enemy.speed_variation = randf_range(45, 60)
			
			enemy.position = world_position
			add_child(enemy)
			enemies_spawned += 1
		
		attempts += 1
	
	print("Spawned shooter enemy: ", enemies_spawned)

func instance_enemies() -> void:
	# Instantiates enemies at random valid locations, ensuring a minimum number of each type
	var player_node = get_node("Player")
	if not player_node:
		return

	var player_position = tilemap.local_to_map(player_node.position)
	var attempts = 0
	var max_attempts = 500
	var enemies_spawned = 0
	
	var total_enemies_to_spawn = randi_range(5, 15)
	
	var min_enemies_per_type = 5
	var enemy_1_count = 0
	var enemy_2_count = 0

	var max_attempts_per_enemy = 10
	while enemies_spawned < total_enemies_to_spawn and attempts < max_attempts:
		var random_position = map[randi() % len(map)]
		var world_position = tilemap.map_to_local(random_position)
		
		if random_position.distance_to(player_position) >= min_distance_from_player:
			var enemy
			if enemy_1_count < min_enemies_per_type:
				enemy = enemy_scene.instantiate()
				enemy_1_count += 1
			elif enemy_2_count < min_enemies_per_type:
				enemy = enemy_2_scene.instantiate()
				enemy_2_count += 1
			else:
				if randf() < 0.5:
					enemy = enemy_scene.instantiate()
					enemy_1_count += 1
				else:
					enemy = enemy_2_scene.instantiate()
					enemy_2_count += 1
			
			var nav_agent = NavigationAgent2D.new()
			enemy.add_child(nav_agent)
			
			# Set random base_speed and speed_variation for each enemy
			enemy.base_speed = randf_range(70, 95)
			enemy.speed_variation = randf_range(10, 20)
			
			enemy.position = world_position
			add_child(enemy)
			enemies_spawned += 1
			max_attempts_per_enemy = 10
		else:
			max_attempts_per_enemy -= 1
			if max_attempts_per_enemy <= 0:
				break
		
		attempts += 1
	
	print("Spawned enemies - Type 1: ", enemy_1_count, ", Type 2: ", enemy_2_count)

func is_tile_occupied(tile_pos: Vector2) -> bool:
	# Checks if a tile is occupied by a specific source ID
	var cell_coords = tilemap.local_to_map(tile_pos)
	return tilemap.get_cell_source_id(ground_layer, cell_coords) != -1

func is_position_valid(check_pos: Vector2) -> bool:
	# Validates if a position is within bounds, on the map, and not occupied
	var cell_coords = tilemap.local_to_map(check_pos)
	if not borders.has_point(cell_coords):
		return false
	if not map.has(cell_coords):
		return false
	if tilemap.get_cell_source_id(ground_layer, cell_coords) != -1:
		return false
	
	for room in rooms:
		var room_rect = Rect2(room.position, room.size)
		if room_rect.has_point(cell_coords):
			return false
	return true
