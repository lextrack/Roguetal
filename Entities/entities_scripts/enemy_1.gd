extends CharacterBody2D

enum enemy_state {IDLE, PATROL, CHASE, ATTACK}
var current_state = enemy_state.IDLE

@export var speed = 90 # Movement speed of the enemy
@export var max_health = 60 # Maximum health of the enemy
@export var attack_damage = 10 # Damage dealt by the enemy's attack
@export var attack_cooldown_time = 1.0 # Time (in seconds) between attacks
@export var attack_range = 25.0 # Distance at which the enemy can attack the player
@export var chase_range = 100.0 # Distance at which the enemy starts chasing the player (for horde mode set a bigger number)
@export var obstacle_avoidance_range = 20.0 # Distance for obstacle detection and avoidance

var current_health
var attack_cooldown = 0.0
var path : Array = []
var path_index = 0
var is_dead = false
var last_known_player_position : Vector2

@onready var navigation_agent : NavigationAgent2D = $NavigationAgent2D if has_node("NavigationAgent2D") else null
@onready var target = get_node("../Player")
@onready var hit_damage_sound: AudioStreamPlayer2D = $hit_damage_sound
@onready var die_enemy_sound: AudioStreamPlayer2D = $die_enemy_sound
@onready var die_sprite: Sprite2D = $Sprites/die_sprite
@onready var attack_sprite: Sprite2D = $Sprites/attack_sprite
@onready var normal_sprite: Sprite2D = $Sprites/normal_movement_enemy
@onready var die_animation_enemy: AnimationPlayer = $Animations/die_animation_enemy
@onready var attack_animation_enemy: AnimationPlayer = $Animations/attack_animation_enemy
@onready var move_animation_enemy: AnimationPlayer = $Animations/move_animation_enemy
@onready var idle_animation_enemy: AnimationPlayer = $Animations/idle_animation_enemy
@onready var idle_sprite: Sprite2D = $Sprites/idle_sprite

var path_update_timer : Timer

func _ready():
	current_health = max_health
	idle_sprite.hide()
	
	# Ensure the navigation agent exists, or create one if not found
	if not navigation_agent:
		navigation_agent = NavigationAgent2D.new()
		add_child(navigation_agent)
	
	# Distance at which the enemy considers it has reached its target position
	navigation_agent.path_desired_distance = 4.0
	
	# Distance at which the enemy considers it has reached the final target
	navigation_agent.target_desired_distance = 4.0
	
	# Maximum distance between path points
	navigation_agent.path_max_distance = 50.0
	
	# Timer to update the path periodically
	path_update_timer = Timer.new()
	path_update_timer.wait_time = 0.5
	path_update_timer.one_shot = false
	path_update_timer.timeout.connect(update_path)
	add_child(path_update_timer)
	path_update_timer.start()
	
	await get_tree().physics_frame
	update_path()
	
	# Hide sprites not needed initially
	die_sprite.hide() if die_sprite else print("Warning: die_sprite not found")
	attack_sprite.hide() if attack_sprite else print("Warning: attack_sprite not found")
		
func _physics_process(delta):
	# Skip processing if the enemy is dead
	if is_dead:
		return
	
	attack_cooldown -= delta
	
	# State machine handling for the enemy
	match current_state:
		enemy_state.IDLE:
			idle_state()
		enemy_state.PATROL:
			patrol_state(delta)
		enemy_state.CHASE:
			chase_state(delta)
		enemy_state.ATTACK:
			attack_state(delta)

func idle_state():
	play_idle_animation()
	
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= chase_range:
		exit_idle_state()
		current_state = enemy_state.CHASE
	elif randf() < 0.01:
		exit_idle_state()
		current_state = enemy_state.PATROL
		update_path()

func patrol_state(delta):
	# Transition to chase if the player is within range
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= chase_range:
		current_state = enemy_state.CHASE
	# Move along the patrol path
	elif path.size() > 0:
		move_along_path(delta)
	else:
		current_state = enemy_state.IDLE

func chase_state(delta):
	# Stop chasing if the player is not valid
	if not is_instance_valid(target):
		current_state = enemy_state.PATROL
		return

	var distance_to_target = global_position.distance_to(target.global_position)
	
	# Attack the player if in range and cooldown is over
	if distance_to_target <= attack_range and attack_cooldown <= 0:
		current_state = enemy_state.ATTACK
	# Stop chasing if the player is too far
	elif distance_to_target > chase_range:
		find_scent_trail()
	else:
		last_known_player_position = target.global_position
		navigation_agent.target_position = last_known_player_position
		
	# Continue moving towards the player
	if not navigation_agent.is_navigation_finished():
		var direction = global_position.direction_to(navigation_agent.get_next_path_position())
		direction = avoid_obstacles(direction) # Avoid obstacles
		velocity = direction * speed
		move_and_slide()
		play_movement_animation(direction)

func exit_idle_state():
	idle_animation_enemy.stop()
	idle_sprite.hide()
	normal_sprite.show()

func find_scent_trail():
	var scent_trails = get_tree().get_nodes_in_group("scent_trail")
	if scent_trails:
		var nearest_trail = scent_trails.reduce(func(a, b): return a if global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position) else b)
		last_known_player_position = nearest_trail.global_position
		navigation_agent.target_position = last_known_player_position
		exit_idle_state()
		current_state = enemy_state.CHASE
	else:
		current_state = enemy_state.IDLE
		play_idle_animation()
		
func play_idle_animation():
	normal_sprite.hide()
	attack_sprite.hide()
	idle_sprite.show()
	idle_animation_enemy.play("idle")
			
func attack_state(delta):
	# Return to chase if the player is out of range
	if not is_instance_valid(target) or global_position.distance_to(target.global_position) > attack_range:
		current_state = enemy_state.CHASE
	# Perform attack if the cooldown is over
	elif attack_cooldown <= 0:
		perform_attack()

func move_along_path(delta):
	# Move along the current path points
	if path_index < path.size():
		var move_direction = global_position.direction_to(path[path_index])
		velocity = move_direction * speed
		move_and_slide()
		play_movement_animation(move_direction)
		
		# Move to the next point if close enough
		if global_position.distance_to(path[path_index]) < 5:
			path_index += 1
	else:
		update_path()

func update_path():
	# Update the path based on the enemy's state
	if not is_instance_valid(navigation_agent):
		return
		
	if current_state == enemy_state.PATROL:
		var random_point = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		navigation_agent.target_position = random_point
	elif current_state == enemy_state.CHASE and is_instance_valid(target):
		last_known_player_position = target.global_position
		navigation_agent.target_position = last_known_player_position

func avoid_obstacles(direction):
	# Avoid obstacles using raycasting
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * obstacle_avoidance_range)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	# Adjust direction if an obstacle is detected
	if result:
		var normal = result.normal
		direction = direction.slide(normal)
	
	return direction

func perform_attack():
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	attack_cooldown = attack_cooldown_time
	exit_idle_state()
	play_attack_animation()

func play_movement_animation(direction):
	exit_idle_state()
	if velocity.length() > 0:
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				move_animation_enemy.play("move_right")
			else:
				move_animation_enemy.play("move_left")
		else:
			if direction.y > 0:
				move_animation_enemy.play("move_down")
			else:
				move_animation_enemy.play("move_up")
	else:
		play_idle_animation()

func play_attack_animation():
	# Play attack animations based on direction
	var direction = global_position.direction_to(target.global_position)
	var animation_name = "attack_right"
	
	if abs(direction.x) > abs(direction.y):
		animation_name = "attack_right" if direction.x > 0 else "attack_left"
	else:
		animation_name = "attack_down" if direction.y > 0 else "attack_up"
	
	normal_sprite.hide()
	attack_sprite.show()
	attack_animation_enemy.play(animation_name)
	await attack_animation_enemy.animation_finished
	normal_sprite.show()
	attack_sprite.hide()

func take_damage(damage: int, bullet = null):
	# Reduce health and die if health drops below zero
	if is_dead:
		return

	current_health -= damage
	if current_health <= 0:
		die()
	else:
		hit_damage_sound.play()
		flash_damage()
		show_damage(damage)
	
	if bullet:
		bullet.queue_free()

func show_damage(damage: int):
	# Show a damage label when hit
	var damage_label_scene = preload("res://UI/ui_scenes/damage_label.tscn")
	var damage_label = damage_label_scene.instantiate() as RichTextLabel
	damage_label.text = str(damage)
	damage_label.global_position = global_position + Vector2(0, -30)
	get_tree().root.add_child(damage_label)

func die():
	if is_dead:
		return

	is_dead = true
	die_enemy_sound.play()
	instance_ammo()
	
	stop_all_animations()
	
	normal_sprite.hide()
	attack_sprite.hide()
	idle_sprite.hide()
	die_sprite.show()
	
	instance_fx()
	die_animation_enemy.play("dead")
	
	await die_animation_enemy.animation_finished
	queue_free()

func flash_damage():
	# Flash the sprite red to indicate damage
	normal_sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	normal_sprite.modulate = Color(1, 1, 1)

func instance_fx():
	# Create a blood effect on death
	var fx_blood = preload("res://Entities/Scenes/FX/fx_blood.tscn")
	var fx = fx_blood.instantiate()
	var random_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	fx.global_position = global_position + random_offset
	fx.rotation = velocity.angle()
	get_tree().current_scene.call_deferred("add_child", fx)

func instance_ammo():
	# Drop ammo with a 60% chance on death
	var drop_chance = randf()
	if drop_chance < 0.6:
		var ammo_scene = preload("res://Interactables/Scenes/ammo_1.tscn")
		var ammo = ammo_scene.instantiate()
		ammo.global_position = global_position
		get_tree().root.call_deferred("add_child", ammo)

func stop_all_animations():
	move_animation_enemy.stop()
	attack_animation_enemy.stop()
	idle_animation_enemy.stop()
	die_animation_enemy.stop()

func _on_chase_box_area_entered(area: Area2D):
	# Start chasing when the player enters the chase area
	if area.is_in_group("follow"):
		current_state = enemy_state.CHASE

func _on_hitbox_area_entered(area: Area2D):
	# Take damage when hit by a bullet
	if area.is_in_group("Bullet"):
		take_damage(area.damage, area)
