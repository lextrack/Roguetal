extends Node2D

var walker
var map
var ground_layer = 0
var rooms = []
const min_distance_from_player = 5

@onready var player_scene = preload("res://Entities/Scenes/Player/player.tscn")
@onready var exit_scene = preload("res://Interactables/Scenes/exit.tscn")
@onready var next_level_scene = preload("res://Interactables/Scenes/next_level.tscn")
@onready var enemy_scene = preload("res://Entities/Scenes/Enemies/enemy_1.tscn")
@onready var health_pickup_scene = preload("res://Interactables/Scenes/health_pickup.tscn")
@onready var tilemap = $Tiles/TileMap
@onready var background_music_player = $BackgroundMusicPlayer

@export var borders = Rect2(1, 1, 70, 50)
@export var exit_portal_spawn_chance: float = 0.5  # 50%

func _ready() -> void:
	randomize()
	generate_level()
	MusicDungeon.play_music_level()
	MusicMainLevel.stop()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart_level"):
		get_tree().reload_current_scene()

func generate_level() -> void:
	walker = Walker_room.new(Vector2(25,25), borders)
	map = walker.walk(500)
	clear_and_set_tiles()
	instance_player()
	instance_portal()
	instance_enemy()
	instance_health_pickup()
	
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

func instance_player():
	var player = player_scene.instantiate()
	add_child(player)
	player.position = map.pop_front() * 16

func instance_portal():
	var random_value = randf()
	var portal
	
	if random_value < exit_portal_spawn_chance:
		portal = exit_scene.instantiate()
		print("Exit portal spawned!")
	else:
		portal = next_level_scene.instantiate()
		print("Next level portal spawned!")
	
	add_child(portal)
	portal.position = walker.get_end_room().position * 16

func instance_enemy() -> void:
	var player_node = get_node("Player")
	if not player_node:
		return

	var player_position = tilemap.local_to_map(player_node.position)
	var attempts = 0
	var max_attempts = 500
	var enemies_spawned = 0
	
	var total_enemies_to_spawn = randi_range(20, 50)

	var max_attempts_per_enemy = 10
	while enemies_spawned < total_enemies_to_spawn and attempts < max_attempts and max_attempts_per_enemy > 0:
		var random_position = map[randi() % len(map)]
		var world_position = tilemap.map_to_local(random_position)
		
		if random_position.distance_to(player_position) >= min_distance_from_player:
			var enemy = enemy_scene.instantiate()
			enemy.position = world_position
			add_child(enemy)
			enemies_spawned += 1
			max_attempts_per_enemy = 10
		else:
			max_attempts_per_enemy -= 1
		
		attempts += 1

func is_tile_occupied(position: Vector2) -> bool:
	var cell_coords = tilemap.local_to_map(position)
	return tilemap.get_cell_source_id(ground_layer, cell_coords) != -1

func is_position_valid(position: Vector2) -> bool:
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
