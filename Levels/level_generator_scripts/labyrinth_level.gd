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
@onready var tilemap = $Tiles/TileMap

@export var borders = Rect2(1, 1, 70, 50)

@onready var timer_light_level: Timer = $timer_light_level
@onready var player: CharacterBody2D = null

var _initialized = false

func _ready() -> void:
	# Called when the scene is ready, sets up the level, plays music
	randomize()
	generate_level()
	MusicDungeon.play_music_level()
	MusicMainLevel.stop()
	
	if get_tree().current_scene.name == "labyrinth_level":
		if timer_light_level:
			if not timer_light_level.timeout.is_connected(Callable(self, "_on_timer_light_level_timeout")):
				timer_light_level.timeout.connect(Callable(self, "_on_timer_light_level_timeout"))
			timer_light_level.start()
			print("Timer started in labyrinth level")  # Añade este print para depuración
		else:
			print("Timer not found in labyrinth level")

func _input(event: InputEvent) -> void:
	# Detects input events, restarts level if necessary
	if Input.is_action_just_pressed("restart_level"):
		get_tree().reload_current_scene()
		
func _on_timer_light_level_timeout() -> void:
	if player and player.has_method("disable_light"):
		player.disable_light()
		print("Timer reached zero, disabling player light")
	timer_light_level.stop()  # Detenemos el timer para que no se reinicie automáticamente
		
func _on_next_level_portal_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body == player:
		# El jugador alcanzó el portal del siguiente nivel
		timer_light_level.stop()  # Detenemos el temporizador
		# Aquí puedes añadir la lógica para pasar al siguiente nivel
		
func generate_level() -> void:
	# Generates the entire level including map, player, enemies, and pickups
	walker = Walker_room.new(Vector2(25,25), borders)
	map = walker.walk(700)
	clear_and_set_tiles()
	instance_player()
	instance_portal()
	create_navigation()
	instance_enemies()
	instance_health_pickup()
	instance_random_powerup()
	
func instance_random_powerup() -> void:
	var powerups = [
		"double_defense",
		"double_speed",
		"double_damage"
	]
	var chosen_powerup = powerups[randi() % powerups.size()]
	
	match chosen_powerup:
		"double_defense":
			instance_double_defense_pickup()
		"double_speed":
			instance_double_speed_pickup()
		"double_damage":
			instance_double_damage_pickup()
	
func instance_double_defense_pickup() -> void:
	var player_node = get_node("Player")
	if not player_node:
		return

	var player_position = tilemap.local_to_map(player_node.position)
	var attempts = 0
	var max_attempts = 100
	var double_defense_pickup_spawned = false
	
	while not double_defense_pickup_spawned and attempts < max_attempts:
		var random_position = map[randi() % len(map)]
		var world_position = tilemap.map_to_local(random_position)
		
		if random_position.distance_to(player_position) >= min_distance_from_player and not is_tile_occupied(world_position):
			var double_defense_pickup = double_defense_pickup_scene.instantiate()
			double_defense_pickup.position = world_position
			add_child(double_defense_pickup)
			double_defense_pickup_spawned = true
		
		attempts += 1
	
func instance_double_speed_pickup() -> void:
	var player_node = get_node("Player")
	if not player_node:
		return

	var player_position = tilemap.local_to_map(player_node.position)
	var attempts = 0
	var max_attempts = 100
	var double_speed_pickup_spawned = false
	
	while not double_speed_pickup_spawned and attempts < max_attempts:
		var random_position = map[randi() % len(map)]
		var world_position = tilemap.map_to_local(random_position)
		
		if random_position.distance_to(player_position) >= min_distance_from_player and not is_tile_occupied(world_position):
			var double_speed_pickup = double_speed_pickup_scene.instantiate()
			double_speed_pickup.position = world_position
			add_child(double_speed_pickup)
			double_speed_pickup_spawned = true
		
		attempts += 1
	
func instance_double_damage_pickup() -> void:
	var player_node = get_node("Player")
	if not player_node:
		return

	var player_position = tilemap.local_to_map(player_node.position)
	var attempts = 0
	var max_attempts = 100
	var double_damage_pickup_spawned = false
	
	while not double_damage_pickup_spawned and attempts < max_attempts:
		var random_position = map[randi() % len(map)]
		var world_position = tilemap.map_to_local(random_position)
		
		if random_position.distance_to(player_position) >= min_distance_from_player and not is_tile_occupied(world_position):
			var double_damage_pickup = double_damage_pickup_scene.instantiate()
			double_damage_pickup.position = world_position
			add_child(double_damage_pickup)
			double_damage_pickup_spawned = true
		
		attempts += 1

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
	self.player = player  # Guardamos la referencia al jugador

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

func instance_enemies() -> void:
	# Instance two types of enemies
	var player_node = get_node("Player")
	if not player_node:
		return

	var player_position = tilemap.local_to_map(player_node.position)
	var attempts = 0
	var max_attempts = 500
	var enemies_spawned = 0
	
	var total_enemies_to_spawn = randi_range(5, 20)

	while enemies_spawned < total_enemies_to_spawn and attempts < max_attempts:
		var random_position = map[randi() % len(map)]
		var world_position = tilemap.map_to_local(random_position)
		
		if random_position.distance_to(player_position) >= min_distance_from_player:
			var enemy = enemy_labyrinth.instantiate()
			
			var nav_agent = NavigationAgent2D.new()
			enemy.add_child(nav_agent)
			
			enemy.position = world_position
			add_child(enemy)
			enemies_spawned += 1
		
		attempts += 1
	
	print("Spawned enemies: ", enemies_spawned)

func is_tile_occupied(position: Vector2) -> bool:
	# Checks if a tile is occupied by a specific source ID
	var cell_coords = tilemap.local_to_map(position)
	return tilemap.get_cell_source_id(ground_layer, cell_coords) != -1

func is_position_valid(position: Vector2) -> bool:
	# Validates if a position is within bounds, on the map, and not occupied
	var cell_coords = tilemap.local_to_map(position)
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
