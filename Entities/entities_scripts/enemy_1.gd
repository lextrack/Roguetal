# ENEMY (ORIGINAL) SCRIPT

extends CharacterBody2D

enum enemy_state {IDLE, PATROL, CHASE, ATTACK, REPOSITION}
var current_state = enemy_state.IDLE

var current_health
var attack_cooldown = 0.0
var path : Array = []
var path_index = 0
var is_dead = false
var last_known_player_position : Vector2
var is_attacking = false
var path_update_timer : Timer
var reposition_timer : Timer

@export var speed = 90 # Movement speed of the enemy
@export var max_health: float = 50.0 # Maximum health points of the enemy
@export var attack_cooldown_time = 0.9 # Time (in seconds) between attacks
@export var chase_range = 170.0 # Distance at which the enemy starts chasing the player
@export var obstacle_avoidance_range = 30.0 # Distance for obstacle detection and avoidance
@export var reposition_distance = 30.0 # Distance the enemy moves when repositioning
@export var attack_damage = 0.3 # Damage dealt by the enemy's attack
@export var attack_range = 25.0 # Distance at which the enemy can attack the player
@export var attack_damage_range = 30.0

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

# Initialize the enemy, set up navigation and timers
func _ready():
	current_health = max_health
	idle_sprite.hide()
	
	if not navigation_agent:
		navigation_agent = NavigationAgent2D.new()
		add_child(navigation_agent)
	
	# Distance at which the enemy considers it has reached its target position
	navigation_agent.path_desired_distance = 4.0

	# Distance at which the enemy considers it has reached the final target
	navigation_agent.target_desired_distance = 4.0

	# Maximum distance between path points
	navigation_agent.path_max_distance = 50.0
	
	path_update_timer = Timer.new()
	path_update_timer.wait_time = 0.5
	path_update_timer.one_shot = false
	path_update_timer.timeout.connect(update_path)
	add_child(path_update_timer)
	path_update_timer.start()
	
	reposition_timer = Timer.new()
	reposition_timer.wait_time = 3.0
	reposition_timer.one_shot = true
	reposition_timer.timeout.connect(end_reposition)
	add_child(reposition_timer)
	
	await get_tree().physics_frame
	update_path()
	
	die_sprite.hide() if die_sprite else print("Warning: die_sprite not found")
	attack_sprite.hide() if attack_sprite else print("Warning: attack_sprite not found")

# Main physics process, handles state machine and cooldowns
func _physics_process(delta):
	if is_dead:
		return
	
	attack_cooldown -= delta
	
	match current_state:
		enemy_state.IDLE:
			idle_state()
		enemy_state.PATROL:
			patrol_state(delta)
		enemy_state.CHASE:
			chase_state(delta)
		enemy_state.ATTACK:
			attack_state(delta)
		enemy_state.REPOSITION:
			reposition_state(delta)

# Idle state: enemy stands still and checks for player proximity
func idle_state():
	play_idle_animation()
	
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= chase_range:
		exit_idle_state()
		current_state = enemy_state.CHASE
	elif randf() < 0.001:
		exit_idle_state()
		current_state = enemy_state.PATROL
		update_path()

# Patrol state: enemy moves randomly if no player is nearby
func patrol_state(delta):
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= chase_range:
		current_state = enemy_state.CHASE
	elif path.size() > 0:
		move_along_path(delta)
	else:
		current_state = enemy_state.IDLE

# Chase state: enemy pursues the player
func chase_state(delta):
	if not is_instance_valid(target):
		current_state = enemy_state.PATROL
		return

	var distance_to_target = global_position.distance_to(target.global_position)
	
	if distance_to_target <= attack_range:
		current_state = enemy_state.ATTACK
	elif distance_to_target > chase_range:
		find_scent_trail()
	else:
		last_known_player_position = target.global_position
		navigation_agent.target_position = last_known_player_position
		
	if not navigation_agent.is_navigation_finished() and not is_attacking:
		var direction = global_position.direction_to(navigation_agent.get_next_path_position())
		direction = avoid_obstacles(direction)
		velocity = direction * speed
		move_and_slide()
		play_movement_animation(direction)

# Attack state: enemy attacks the player when in range
func attack_state(delta):
	var distance_to_target = global_position.distance_to(target.global_position)
	
	if not is_instance_valid(target) or distance_to_target > attack_range * 1.5:
		current_state = enemy_state.CHASE
		is_attacking = false
	elif attack_cooldown <= 0 and distance_to_target <= attack_damage_range:
		perform_attack()
	else:
		var direction = global_position.direction_to(target.global_position)
		if distance_to_target > attack_damage_range:
			velocity = direction * speed
		else:
			velocity = direction * (speed * 0.5)
		move_and_slide()
		play_movement_animation(direction)

# Reposition state: enemy moves to a new position after attacking
func reposition_state(delta):
	var direction = global_position.direction_to(navigation_agent.get_next_path_position())
	direction = avoid_obstacles(direction)
	velocity = direction * speed
	move_and_slide()
	play_movement_animation(direction)
	
	if navigation_agent.is_navigation_finished():
		current_state = enemy_state.CHASE

# End reposition state and return to chase state
func end_reposition():
	current_state = enemy_state.CHASE

# Exit idle state, hide idle sprite and show normal sprite
func exit_idle_state():
	idle_animation_enemy.stop()
	idle_sprite.hide()
	normal_sprite.show()

# Look for player's scent trail when losing sight of the player
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

# Play idle animation
func play_idle_animation():
	normal_sprite.hide()
	attack_sprite.hide()
	idle_sprite.show()
	idle_animation_enemy.play("idle")

# Perform an attack on the player
func perform_attack():
	is_attacking = true
	if global_position.distance_to(target.global_position) <= attack_damage_range:
		if target.has_method("take_damage") and not target.is_in_portal:
			target.take_damage(attack_damage)
	attack_cooldown = attack_cooldown_time
	play_attack_animation()

# Move along the calculated path
func move_along_path(delta):
	if path_index < path.size():
		var move_direction = global_position.direction_to(path[path_index])
		velocity = move_direction * speed
		move_and_slide()
		play_movement_animation(move_direction)
		
		if global_position.distance_to(path[path_index]) < 5:
			path_index += 1
	else:
		update_path()

# Update the navigation path
func update_path():
	if not is_instance_valid(navigation_agent):
		return
		
	if current_state == enemy_state.PATROL:
		var random_point = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		navigation_agent.target_position = random_point
	elif current_state == enemy_state.CHASE and is_instance_valid(target):
		last_known_player_position = target.global_position
		navigation_agent.target_position = last_known_player_position

# Avoid obstacles while moving (almost)
func avoid_obstacles(direction):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * obstacle_avoidance_range)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	if result:
		var normal = result.normal
		direction = direction.slide(normal)
	
	return direction

# Play movement animation based on direction
func play_movement_animation(direction):
	if is_attacking:
		return
	
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

# Play attack animation based on direction to player
func play_attack_animation():
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
	is_attacking = false

# Handle taking damage
func take_damage(damage: int, bullet = null):
	if is_dead:
		return

	if current_health == null:
		current_health = max_health

	current_health -= damage
	if current_health <= 0:
		current_health = 0
		die()
	else:
		hit_damage_sound.play()
		flash_damage()
		show_damage(damage)
	
	if bullet:
		bullet.queue_free()

# Show damage number when hit
func show_damage(damage: int):
	var damage_label_scene = preload("res://UI/ui_scenes/damage_label.tscn")
	var damage_label = damage_label_scene.instantiate() as RichTextLabel
	damage_label.text = str(damage)
	damage_label.global_position = global_position + Vector2(0, -30)
	get_tree().root.add_child(damage_label)

# Handle enemy death
func die():
	if is_dead:
		return

	is_dead = true
	die_enemy_sound.play()
	instance_ammo()
	
	player_data.kill_count += 1
	player_data.update_kill_streak()
	
	stop_all_animations()
	
	normal_sprite.hide()
	attack_sprite.hide()
	idle_sprite.hide()
	die_sprite.show()
	
	instance_fx()
	die_animation_enemy.play("dead")
	
	await die_animation_enemy.animation_finished
	queue_free()

# Flash red when taking damage
func flash_damage():
	normal_sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	normal_sprite.modulate = Color(1, 1, 1)

# Create blood effect on death
func instance_fx():
	var fx_blood = preload("res://Entities/Scenes/FX/fx_blood.tscn")
	var fx = fx_blood.instantiate()
	var random_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	fx.global_position = global_position + random_offset
	fx.rotation = velocity.angle()
	get_tree().current_scene.call_deferred("add_child", fx)

# Spawn ammo pickup on death
func instance_ammo():
	var drop_chance = randf()
	if drop_chance < 0.5:
		var ammo_scene = preload("res://Interactables/Scenes/ammo_1.tscn")
		var ammo = ammo_scene.instantiate()
		ammo.global_position = global_position
		get_tree().root.call_deferred("add_child", ammo)

# Stop all animations
func stop_all_animations():
	move_animation_enemy.stop()
	attack_animation_enemy.stop()
	idle_animation_enemy.stop()
	die_animation_enemy.stop()

# Start chasing when player enters detection area
func _on_chase_box_area_entered(area: Area2D):
	if area.is_in_group("follow"):
		current_state = enemy_state.CHASE

# Take damage when hit by a bullet
func _on_hitbox_area_entered(area: Area2D):
	if area.is_in_group("Bullet"):
		take_damage(area.damage, area)
