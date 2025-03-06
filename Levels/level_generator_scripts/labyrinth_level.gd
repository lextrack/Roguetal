extends Node2D

var walker
var map
var ground_layer = 0
var rooms = []
const min_distance_from_player = 5

@onready var player_scene = preload("res://Entities/Scenes/Player/player.tscn")
@onready var exit_scene = preload("res://Interactables/Scenes/exit_portal.tscn")
@onready var next_level_scene = preload("res://Interactables/Scenes/next_level.tscn")
@onready var enemy_labyrinth = preload("res://Entities/Scenes/Enemies/enemy_labyrinth.tscn")
@onready var health_pickup_scene = preload("res://Interactables/Scenes/health_pickup.tscn")
@onready var double_damage_pickup_scene = preload("res://Interactables/Scenes/double_damage_pickup.tscn")
@onready var double_defense_pickup_scene = preload("res://Interactables/Scenes/double_defense_pickup_scene.tscn")
@onready var double_speed_pickup_scene = preload("res://Interactables/Scenes/double_speed_pickup.tscn")
@onready var bullet_hell_pickup_scene = preload("res://Interactables/Scenes/bullet_hell_pickup_scene.tscn")
@onready var slow_enemy_pickup_scene = preload("res://Interactables/Scenes/slow_enemy_pickup.tscn")
@onready var shotgun_shell_incendiary_pickup = preload("res://Interactables/Scenes/shotgun_shell_incendiary.tscn")
@onready var critical_chance_pickup = preload("res://Interactables/Scenes/critical_chance_pickup.tscn")
@onready var tilemap = $Tiles/TileMap

@export var borders = Rect2(1, 1, 70, 55)

@onready var timer_light_level: Timer = $timer_light_level
@onready var player: CharacterBody2D = null

func _ready() -> void:
	randomize()
	generate_level()
	
	MusicManager.ensure_music_playing()
	
	if get_tree().current_scene.name == "labyrinth_level":
		await get_tree().process_frame
			
		if timer_light_level:
			if not timer_light_level.timeout.is_connected(Callable(self, "_on_timer_light_level_timeout")):
				timer_light_level.timeout.connect(Callable(self, "_on_timer_light_level_timeout"))
			print("Timer light level connected and started")
			timer_light_level.start()
		else:
			print("Timer not found in labyrinth level")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart_level"):
		get_tree().reload_current_scene()
		
func _on_timer_light_level_timeout() -> void:
	if player and is_instance_valid(player):
		print("Disabling player light from timer")
		player.disable_light()
	else:
		print("Player reference invalid in timer timeout. Player value: ", player)
	timer_light_level.stop()
		
func _on_next_level_portal_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body == player:
		timer_light_level.stop()
		
func generate_level() -> void:
	walker = Walker_room.new(Vector2(25,25), borders)
	map = walker.walk(700)
	clear_and_set_tiles()
	instance_player()
	instance_portal()
	create_navigation()
	
	var current_scene = get_tree().current_scene.scene_file_path
	var enemy_counts = EnemyScalingManagerGlobal.get_enemy_counts(current_scene)
	
	instance_enemies(enemy_counts.normal_enemies)
	instance_health_pickup()
	instance_random_powerup()
	
func instance_random_powerup() -> void:
	var powerups = [
		{"name": "double_defense", "weight": 20},
		{"name": "double_speed", "weight": 28},
		{"name": "double_damage", "weight": 17},
		{"name": "bullet_hell", "weight": 9},
		{"name": "critical_chance", "weight": 12},
		{"name": "slow_enemy", "weight": 10},
		{"name": "incendiary_shotgun", "weight": 98} # 11
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
		"bullet_hell":
			instance_bullet_hell_pickup()
		"critical_chance":
			instance_critical_chance_pickup()
		"slow_enemy":
			instance_slow_enemy_pickup()
		"incendiary_shotgun":
			instance_shotgun_shell_incendiary_pickup()
			
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

func instance_bullet_hell_pickup() -> void:
	instance_specific_pickup(bullet_hell_pickup_scene)
	
func instance_critical_chance_pickup() -> void:
	instance_specific_pickup(critical_chance_pickup)
	
func instance_slow_enemy_pickup() -> void:
	instance_specific_pickup(slow_enemy_pickup_scene)
	
func instance_shotgun_shell_incendiary_pickup() -> void:
	instance_specific_pickup(shotgun_shell_incendiary_pickup)

func create_navigation():
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

func instance_health_pickup() -> void:
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
	var using_cells: Array = []
	var all_cells: Array = tilemap.get_used_cells(ground_layer)
	tilemap.clear()
	walker.queue_free()

	for tile in all_cells:
		if !map.has(Vector2(tile.x, tile.y)):
			using_cells.append(tile)
			
	tilemap.set_cells_terrain_connect(ground_layer, using_cells, ground_layer, ground_layer, false)
	tilemap.set_cells_terrain_path(ground_layer, using_cells, ground_layer, ground_layer, false)

func instance_player() -> void:
	var player_instance = player_scene.instantiate()
	player_instance.position = map[0] * tilemap.cell_quadrant_size
	add_child(player_instance)
	player = player_instance
	print("Player instanced at: ", player_instance.position)

func instance_portal():
	var exit_portal = exit_scene.instantiate()
	var next_level_portal = next_level_scene.instantiate()
	
	add_child(exit_portal)
	add_child(next_level_portal)
	
	var end_room_position = walker.get_end_room().position * 16
	var other_position = get_other_portal_position(end_room_position)
	
	exit_portal.position = end_room_position
	next_level_portal.position = other_position

func get_other_portal_position(existing_position):
	var attempts = 0
	var max_attempts = 100
	var min_distance = 160
	
	while attempts < max_attempts:
		var random_position = map[randi() % len(map)] * 16
		if random_position.distance_to(existing_position) >= min_distance:
			return random_position
		attempts += 1
	
	return map[randi() % len(map)] * 16

func instance_enemies(base_count: int = 6) -> void:
	var player_node = get_node("Player")
	if not player_node:
		return

	var player_position = tilemap.local_to_map(player_node.position)
	var attempts = 0
	var max_attempts = 500
	var enemies_spawned = 0
	
	var total_enemies_to_spawn = randi_range(base_count, base_count + 3)
	
	while enemies_spawned < total_enemies_to_spawn and attempts < max_attempts:
		var random_position = map[randi() % len(map)]
		var world_position = tilemap.map_to_local(random_position)
		
		if random_position.distance_to(player_position) >= min_distance_from_player:
			var enemy = enemy_labyrinth.instantiate()
			
			var nav_agent = NavigationAgent2D.new()
			enemy.add_child(nav_agent)
			
			enemy.base_speed = randf_range(85, 110)
			enemy.speed_variation = randf_range(20, 30)
			
			enemy.position = world_position
			add_child(enemy)
			enemies_spawned += 1
		
		attempts += 1
	
	print("Spawned enemies: ", enemies_spawned)

func is_tile_occupied(tile_pos: Vector2) -> bool:
	var cell_coords = tilemap.local_to_map(tile_pos)
	return tilemap.get_cell_source_id(ground_layer, cell_coords) != -1

func is_position_valid(check_pos: Vector2) -> bool:
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
