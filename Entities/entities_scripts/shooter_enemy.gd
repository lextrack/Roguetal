extends CharacterBody2D

enum enemy_state {IDLE, PATROL, CHASE, ATTACK, REPOSITION}
var current_state = enemy_state.IDLE
var current_animation_state = "idle"

static var last_hit_sound_time = 0
static var last_death_sound_time = 0
static var last_attack_sound_time = 0
const HIT_SOUND_COOLDOWN = 0.1
const DEATH_SOUND_COOLDOWN = 0.1
const ATTACK_SOUND_COOLDOWN = 0.5

var current_health
var attack_cooldown = 0.0
var path : Array = []
var path_index = 0
var is_dead = false
var last_known_player_position : Vector2
var is_attacking = false
var path_update_timer : Timer
var reposition_timer : Timer
var idle_timer : Timer

@export var optimal_attack_distance = 130.0 # Optimal distance to attack from
@export var strafe_speed_multiplier = 0.7 # Speed multiplier while strafing
@export var retreat_threshold = 0.3 # Health threshold for retreat (30%)
@export var dodge_cooldown = 2.0 # Time between dodges
@export var dodge_chance = 0.3 # Probability to perform a dodge
@export var flank_distance = 100.0 # Distance for flanking maneuvers
@export var max_shots_before_reposition = 3 # Maximum shots before repositioning
@export var optimal_distance_tolerance = 30.0 # Tolerance range for optimal distance
@export var distance_adjustment_speed = 0.2 # Speed for position adjustments

var current_shots = 0 # Counter for shots fired
var dodge_timer = 0.0 # Timer for dodge cooldown
var is_strafing = false # Strafing movement state
var strafe_direction = 1 # Strafing direction (1 or -1)
var last_strafe_change = 0.0 # Timer for strafe direction changes
var speed # The actual speed of this enemy instance
var max_allowed_speed = 110 # Maximum allowed speed for any enemy

@export var projectile_detection_radius_bazooka = 110.0 # Detection radius for bazooka projectiles
@export var projectile_detection_radius_normal = 85.0 # Detection radius for standard projectiles
@export var dodge_speed_multiplier_bazooka = 1.2 # Dodge speed multiplier for bazooka
@export var dodge_speed_multiplier_normal = 1.3 # Dodge speed multiplier for standard projectiles
@export var dodge_duration = 0.3 # Duration of dodge movement

@export var base_damage = 0.2
@export var max_accuracy_distance = 70.0
@export var min_attack_distance = 50.0
@export var miss_chance = 0.3  # 30% probability to miss the shot
@export var base_miss_chance = 0.4
@export var max_damage_variability = 0.1
@export var base_speed = 100 # The base movement speed of the enemy
@export var speed_variation = 30 # The range of speed variation
@export var max_health: float = 60.0 # The maximum health points of the enemy
@export var attack_cooldown_time = 0.7 # Time (in seconds) between enemy attacks
@export var chase_range = 165.0 # Distance at which the enemy starts to chase the player
@export var obstacle_avoidance_range = 10.0 # Distance for detecting and avoiding obstacles
@export var reposition_distance = 40.0 # Distance the enemy moves to reposition during combat
@export var attack_damage = 0.2 # Damage dealt by the enemy in each attack
@export var attack_range = 85.0 # Distance within which the enemy can attack the player
@export var attack_damage_range = 30.0 # Range of variability in the enemy's attack damage
@export var idle_time_min = 2.0 # Minimum time to stay in idle state
@export var idle_time_max = 4.0 # Maximum time to stay in idle state

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
@onready var timer_direction: Timer = $timer_direction if has_node("timer_direction") else null
@onready var attack_sound: AudioStreamPlayer2D = $attack_sound

# Initialize the enemy, set up navigation and timers
func _ready():
	randomize()
	initialize_speed()
	initialize_health()
	setup_sprites()
	setup_navigation()
	setup_timers()
	setup_initial_state()
	connect_signals()

func initialize_speed():
	var variation_percent = randf_range(-speed_variation, speed_variation) / 100.0
	speed = base_speed * (1 + variation_percent)
	speed = min(speed, max_allowed_speed)

func initialize_health():
	current_health = max_health

func setup_sprites():
	idle_sprite.hide()
	if die_sprite:
		die_sprite.hide()
	else:
		print("Warning: die_sprite not found")
		
	if attack_sprite:
		attack_sprite.hide()
	else:
		print("Warning: attack_sprite not found")

func setup_navigation():
	if not navigation_agent:
		navigation_agent = NavigationAgent2D.new()
		add_child(navigation_agent)
	
	navigation_agent.path_desired_distance = 2.0
	navigation_agent.target_desired_distance = 2.0
	navigation_agent.path_max_distance = 50.0

func setup_timers():
	setup_path_update_timer()
	setup_reposition_timer()
	setup_idle_timer()

func setup_path_update_timer():
	path_update_timer = Timer.new()
	path_update_timer.wait_time = 0.2
	path_update_timer.one_shot = false
	path_update_timer.timeout.connect(update_path)
	add_child(path_update_timer)
	path_update_timer.start()

func setup_reposition_timer():
	reposition_timer = Timer.new()
	reposition_timer.wait_time = 2.0
	reposition_timer.one_shot = true
	reposition_timer.timeout.connect(end_reposition)
	add_child(reposition_timer)

func setup_idle_timer():
	idle_timer = Timer.new()
	idle_timer.one_shot = true
	idle_timer.timeout.connect(end_idle_state)
	add_child(idle_timer)

func setup_initial_state():
	await get_tree().physics_frame
	update_path()

func connect_signals():
	if timer_direction and not timer_direction.timeout.is_connected(_on_timer_direction_timeout):
		timer_direction.timeout.connect(_on_timer_direction_timeout)

# Verify if the enemy can attack the player (something in front of the enemy)
func has_clear_shot() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)

	return not result or result.collider == target

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
	if not idle_animation_enemy.is_playing():
		play_idle_animation()
	
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= chase_range:
		end_idle_state()
		current_state = enemy_state.CHASE

# End idle state and transition to patrol
func end_idle_state():
	idle_timer.stop()
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
		enter_idle_state()
		
func _on_timer_direction_timeout() -> void:
	if current_state == enemy_state.PATROL:
		update_path()

# Enter idle state and start idle timer
func enter_idle_state():
	current_state = enemy_state.IDLE
	idle_timer.start(randf_range(idle_time_min, idle_time_max))
	play_idle_animation()

# Chase state: enemy pursues the player
func chase_state(delta):
	if not is_instance_valid(target):
		enter_idle_state()
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
	if not is_instance_valid(target) or target.is_dead:
		current_state = enemy_state.CHASE
		is_attacking = false
		stop_attack_animation()
		return

	var distance_to_target = global_position.distance_to(target.global_position)
	var direction_to_target = global_position.direction_to(target.global_position)

	if distance_to_target < min_attack_distance:
		velocity = -direction_to_target * speed
		move_and_slide()
		play_movement_animation(-direction_to_target)
	elif distance_to_target > attack_range:
		current_state = enemy_state.CHASE
	else:
		handle_combat_movement(delta, distance_to_target, direction_to_target)
		
		if attack_cooldown <= 0 and has_clear_shot():
			perform_attack()
			current_shots += 1
			
			if current_shots >= max_shots_before_reposition:
				initiate_reposition()
				current_shots = 0
				
func handle_combat_movement(delta, distance_to_target, direction_to_target):
	dodge_timer = max(0, dodge_timer - delta)
	
	# Si está atacando, no permitir otros movimientos
	if is_attacking:
		return
		
	# Si está esquivando, no permitir otros movimientos
	if current_animation_state == "dodge":
		return
	
	# Comprobar si debe esquivar
	if should_dodge():
		perform_dodge()
		return
	
	# Movimiento normal de combate
	update_strafe_direction()
	var movement = calculate_movement_vector(distance_to_target, direction_to_target)
	apply_smooth_movement(movement)
	
func update_strafe_direction():
	if not is_strafing:
		is_strafing = true
		strafe_direction = 1 if randf() > 0.5 else -1
		last_strafe_change = Time.get_ticks_msec() / 1000.0

	elif Time.get_ticks_msec() / 1000.0 - last_strafe_change > 2.5:
		strafe_direction *= -1
		last_strafe_change = Time.get_ticks_msec() / 1000.0

func calculate_movement_vector(distance_to_target, direction_to_target) -> Vector2:
	var movement = Vector2.ZERO
	
	var strafe_vector = direction_to_target.rotated(PI/2) * strafe_direction
	movement += strafe_vector * speed * strafe_speed_multiplier
	
	var distance_diff = distance_to_target - optimal_attack_distance
	if abs(distance_diff) > optimal_distance_tolerance:
		var adjustment = direction_to_target * distance_diff * distance_adjustment_speed

		adjustment = adjustment.limit_length(speed * 0.5)
		movement += adjustment
	
	return movement

func is_projectile_threatening(projectile: Node2D) -> bool:
	var projectile_type = get_projectile_type(projectile)
	var detection_radius = projectile_detection_radius_bazooka if projectile_type == "bazooka" else projectile_detection_radius_normal
	
	var dist_to_projectile = global_position.distance_to(projectile.global_position)
	if dist_to_projectile > detection_radius:
		return false
	
	if projectile_type == "shotgun":
		return is_in_shotgun_spread(projectile)
	
	var projectile_velocity = projectile.velocity if "velocity" in projectile else Vector2.ZERO
	if projectile_velocity == Vector2.ZERO:
		return false
	
	var time_to_impact = predict_time_to_impact(projectile)
	var threat_level = calculate_threat_level(projectile_type, time_to_impact, dist_to_projectile)
	
	return threat_level > 0.7
	
func is_in_shotgun_spread(projectile: Node2D) -> bool:
	var dist_to_projectile = global_position.distance_to(projectile.global_position)
	return dist_to_projectile < 60.0
	
func get_nearest_threatening_projectile() -> Node2D:
	var nearest_dist = INF
	var nearest = null
	
	for projectile in get_tree().get_nodes_in_group("player_projectiles"):
		if not is_projectile_threatening(projectile):
			continue
			
		var dist = global_position.distance_to(projectile.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = projectile
	
	return nearest

func get_projectile_type(projectile: Node2D) -> String:
	if projectile.is_in_group("bazooka"):
		return "bazooka"
	elif projectile.is_in_group("shotgun"):
		return "shotgun"
	elif projectile.is_in_group("m16"):
		return "m16"
	else:
		return "normal"

func predict_time_to_impact(projectile: Node2D) -> float:
	var projectile_velocity = projectile.velocity if "velocity" in projectile else Vector2.ZERO
	var relative_position = projectile.global_position - global_position
	var speed = projectile_velocity.length()
	
	if speed == 0:
		return INF
		
	var relative_velocity = projectile_velocity - velocity
	var prediction = relative_position.length() / relative_velocity.length()
	return prediction * (1.0 + randf_range(-0.1, 0.1))

func calculate_threat_level(projectile_type: String, time_to_impact: float, distance: float) -> float:
	var base_threat = 1.0 - (time_to_impact / 1.0)
	
	match projectile_type:
		"bazooka":
			return base_threat * 1.4
		"shotgun":
			return base_threat * 0.7
		"m16":
			return base_threat * 1.6
		_:
			return base_threat
			
func apply_smooth_movement(movement: Vector2):
	movement = movement.limit_length(speed)
	
	if velocity.length() > 0:
		var smooth_factor = 0.15
		velocity = velocity.lerp(movement, smooth_factor)
	else:
		velocity = movement
	
	velocity = avoid_obstacles(velocity.normalized()) * speed
	move_and_slide()
	play_movement_animation(velocity.normalized())

func initiate_reposition():
	current_state = enemy_state.REPOSITION
	
	var flank_angle = randf_range(PI/4, PI/2) * (1 if randf() > 0.5 else -1)
	var target_position = target.global_position + Vector2.RIGHT.rotated(flank_angle) * flank_distance
	
	navigation_agent.target_position = target_position
	reposition_timer.start(randf_range(1.0, 2.0))

func should_dodge() -> bool:
	if dodge_timer > 0:
		return false
		
	var nearby_projectiles = get_tree().get_nodes_in_group("player_projectiles")
	for projectile in nearby_projectiles:
		if is_projectile_threatening(projectile):
			return randf() < dodge_chance
			
	return false

func perform_dodge():
	var nearest_projectile = get_nearest_threatening_projectile()
	if not nearest_projectile:
		return
	
	current_animation_state = "dodge"
	var projectile_type = get_projectile_type(nearest_projectile)
	var dodge_speed = speed * (dodge_speed_multiplier_bazooka if projectile_type == "bazooka" else dodge_speed_multiplier_normal)
	
	var dodge_direction = calculate_optimal_dodge_direction(nearest_projectile)
	execute_dodge_movement(dodge_direction, dodge_speed)
	
func calculate_optimal_dodge_direction(projectile: Node2D) -> Vector2:
	var to_projectile = projectile.global_position - global_position
	var projectile_velocity = projectile.velocity if "velocity" in projectile else Vector2.ZERO
	var perpendicular = to_projectile.rotated(PI/2).normalized()
	var to_target = target.global_position - global_position
	
	match get_projectile_type(projectile):
		"bazooka":
			var wide_dodge = perpendicular.rotated(PI/6 * strafe_direction)
			if to_target.length() < optimal_attack_distance:
				return (wide_dodge + to_target.normalized() * 0.5).normalized()
			return wide_dodge
			
		"shotgun":
			return (perpendicular + to_projectile.normalized()).normalized()
			
		"m16":
			var dodge_angle = PI/4 * strafe_direction
			var quick_dodge = perpendicular.rotated(dodge_angle)
			if to_target.length() < optimal_attack_distance:
				return (quick_dodge + to_target.normalized() * 0.3).normalized()
			return quick_dodge
			
		_:
			if to_target.length() < optimal_attack_distance:
				return (perpendicular + to_target.normalized()).normalized()
			return perpendicular

func execute_dodge_movement(dodge_direction: Vector2, dodge_speed: float):
	var initial_velocity = dodge_direction * dodge_speed
	var final_velocity = initial_velocity * 0.3
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_method(
		func(v: Vector2):
			velocity = v
			move_and_slide(),
		initial_velocity,
		final_velocity,
		dodge_duration
	)
	
	# Restaurar estado normal después del dodge
	tween.tween_callback(func():
		current_animation_state = "idle"
	)
	
	dodge_timer = dodge_cooldown
	
func get_nearest_projectile() -> Node2D:
	var nearest_dist = INF
	var nearest = null
	
	for projectile in get_tree().get_nodes_in_group("player_projectiles"):
		var dist = global_position.distance_to(projectile.global_position)
		if dist < nearest_dist and dist < 50.0:
			nearest_dist = dist
			nearest = projectile
	
	return nearest

func reposition_state(delta):
	var direction = global_position.direction_to(navigation_agent.get_next_path_position())
	direction = avoid_obstacles(direction)
	velocity = direction * speed
	move_and_slide()
	play_movement_animation(direction)
	
	if navigation_agent.is_navigation_finished():
		var target_position = global_position + direction.rotated(PI / 4) * reposition_distance
		navigation_agent.target_position = target_position
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
		enter_idle_state()

# Play idle animation
func play_idle_animation():
	normal_sprite.hide()
	attack_sprite.hide()
	idle_sprite.show()
	idle_animation_enemy.play("idle")

# Perform an attack on the player
func perform_attack():
	is_attacking = true
	current_animation_state = "attack"

	if global_position.distance_to(target.global_position) <= attack_range:
		var successful_hit = calculate_attack_effectiveness()
		play_attack_animation()
		
	attack_cooldown = attack_cooldown_time
	
func calculate_attack_effectiveness() -> bool:
	var distance_to_target = global_position.distance_to(target.global_position)
	
	var optimal_distance_factor = 1.0 - abs(distance_to_target - optimal_attack_distance) / optimal_attack_distance
	optimal_distance_factor = clamp(optimal_distance_factor, 0.3, 1.0)
	
	var target_movement_penalty = 0.0
	if target.velocity.length() > 0:
		target_movement_penalty = 0.2
	
	var final_accuracy = (1.0 - base_miss_chance) * optimal_distance_factor * (1.0 - target_movement_penalty)
	
	if player_data.kill_count >= 25:
		final_accuracy *= 0.8
	
	var successful_hit = randf() < final_accuracy
	
	if successful_hit:
		var damage_variability = randf_range(-max_damage_variability, max_damage_variability)
		var damage_distance_factor = optimal_distance_factor * 0.3 + 0.7  # La distancia afecta al daño pero no demasiado
		var final_damage = base_damage * damage_distance_factor + damage_variability
		target.take_damage(final_damage)
	
	return successful_hit

func stop_attack_animation():
	if attack_animation_enemy.is_playing():
		attack_animation_enemy.stop()
	attack_sprite.hide()
	normal_sprite.show()

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
	var avoidance_rays = [
		direction,
		direction.rotated(PI/8),
		direction.rotated(-PI/8)
	]
	
	for ray in avoidance_rays:
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + ray * obstacle_avoidance_range
		)
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		
		if not result:
			return ray
	
	return direction.rotated(PI/4 * (-1 if randf() > 0.5 else 1))

# Play movement animation based on direction
func play_movement_animation(direction):
	# Si está en una animación prioritaria, no interrumpir
	if current_animation_state in ["dodge", "attack"]:
		return
	
	if velocity.length() > 0:
		current_animation_state = "walk"
		if not move_animation_enemy.is_playing():
			move_animation_enemy.play("walk")
		
		if direction.x != 0:
			normal_sprite.flip_h = direction.x < 0
	else:
		current_animation_state = "idle"
		play_idle_animation()

# Play attack animation based on direction to player
func play_attack_animation():
	if not is_instance_valid(target):
		return
	
	move_animation_enemy.stop()
	normal_sprite.hide()
	
	var direction = global_position.direction_to(target.global_position)
	attack_sprite.flip_h = direction.x < 0
	attack_sprite.show()
	
	attack_animation_enemy.play("attack")
	play_attack_sound()
	
	await attack_animation_enemy.animation_finished
	normal_sprite.show()
	attack_sprite.hide()
	is_attacking = false

func play_attack_sound():
	if attack_sound and not attack_sound.playing:
		attack_sound.play()

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
		play_hit_sound()
		flash_damage()
		show_damage(damage)
	
	if bullet:
		bullet.queue_free()

# Play hit sound with cooldown
func play_hit_sound():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_hit_sound_time > HIT_SOUND_COOLDOWN:
		hit_damage_sound.play()
		last_hit_sound_time = current_time

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
	play_death_sound()
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

# Play death sound with cooldown
func play_death_sound():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_death_sound_time > DEATH_SOUND_COOLDOWN:
		die_enemy_sound.play()
		last_death_sound_time = current_time

# Flash red when taking damage
func flash_damage():
	normal_sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	normal_sprite.modulate = Color(1, 1, 1)

# Create fluid effect on death
func instance_fx():
	var fx_blood = preload("res://Entities/Scenes/FX/fx_fluid_robot.tscn")
	var fx = fx_blood.instantiate()
	var random_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	fx.global_position = global_position + random_offset
	fx.rotation = velocity.angle()
	get_tree().current_scene.call_deferred("add_child", fx)

# Spawn ammo pickup on death
func instance_ammo():
	var drop_chance = randf()
	if drop_chance < 0.9:
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
