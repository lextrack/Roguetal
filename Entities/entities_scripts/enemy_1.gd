extends CharacterBody2D

enum enemy_state {IDLE, PATROL, CHASE, ATTACK, REPOSITION}
var current_state = enemy_state.IDLE
var current_animation_state = "idle"

static var last_hit_sound_time = 0
static var last_death_sound_time = 0
static var last_attack_sound_time = 0
const HIT_SOUND_COOLDOWN = 0.1
const DEATH_SOUND_COOLDOWN = 0.1
const ATTACK_SOUND_COOLDOWN = 0.7

var slow_effect_particles: GPUParticles2D
var base_modulate: Color = Color(1, 1, 1, 1)
var slow_tween: Tween

var fire_damage = 3.0
var fire_duration = 3.0
var fire_tick_time = 0.3
var is_burning = false
var fire_particles: GPUParticles2D
var fire_timer: Timer
var fire_tick_timer: Timer
var burn_tween: Tween

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
var speed # The actual speed of this enemy instance
var max_allowed_speed = 115 # Maximum allowed speed for any enemy

@export var base_speed = 95 # The base movement speed of the enemy
@export var speed_variation = 20 # The range of speed variation
@export var max_health: float = 40.0 # The maximum health points of the enemy
@export var attack_cooldown_time = 0.6 # Time (in seconds) between enemy attacks
@export var chase_range = 170.0 # Distance at which the enemy starts to chase the player
@export var obstacle_avoidance_range = 5.0 # Distance for detecting and avoiding obstacles
@export var reposition_distance = 30.0 # Distance the enemy moves to reposition during combat
@export var attack_damage = 0.18 # Damage dealt by the enemy in each attack
@export var attack_range = 4.0 # Distance within which the enemy can attack the player
@export var attack_damage_range = 20.0 # Range of variability in the enemy's attack damage
@export var idle_time_min = 3.0 # Minimum time to stay in idle state
@export var idle_time_max = 6.0 # Maximum time to stay in idle state

@onready var navigation_agent : NavigationAgent2D = $NavigationAgent2D if has_node("NavigationAgent2D") else null
@onready var target = get_node("../Player")
@onready var power_up_manager = target.get_node("PowerUpManager") if target else null
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
@onready var fire_particles_scene = preload("res://Entities/Scenes/FX/fire_particles.tscn")

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
	setup_fire_system()
	
	if power_up_manager and not power_up_manager.is_connected("power_up_changed", Callable(self, "_on_power_up_changed")):
		power_up_manager.connect("power_up_changed", Callable(self, "_on_power_up_changed"))
		
func _on_power_up_changed(type: int, multiplier: float):
	if type == PowerUpTypes.PowerUpType.ENEMY_SLOW:
		update_speed_with_slow()

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
	
	var speed_multiplier = 1.0
	if distance_to_target > chase_range * 0.7:
		speed_multiplier = 1.2
	elif distance_to_target < attack_range * 1.5:
		speed_multiplier = 0.6
		
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
		velocity = direction * speed * speed_multiplier
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
	
	if distance_to_target <= attack_range:
		if attack_cooldown > 0:
			velocity = Vector2.ZERO
		else:
			perform_attack()
	else:
		velocity = direction_to_target * speed * 1.2
		move_and_slide()
		play_movement_animation(direction_to_target)

# Reposition state: enemy moves to a new position after attacking
func reposition_state(delta):
	var to_target = global_position.direction_to(target.global_position)
	var distance = global_position.distance_to(target.global_position)
	
	if distance < attack_range * 1.5:
		var escape_direction = -to_target.rotated(PI/4 * (1 if randf() > 0.5 else -1))
		velocity = escape_direction * speed
	else:
		var direction = global_position.direction_to(navigation_agent.get_next_path_position())
		direction = avoid_obstacles(direction)
		velocity = direction * speed
		
	move_and_slide()
	play_movement_animation(velocity.normalized())
	
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
		if target.has_method("take_damage") and not target.is_dead and not target.is_in_portal:
			target.take_damage(attack_damage)
	
	play_attack_animation()
	attack_cooldown = attack_cooldown_time

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
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * obstacle_avoidance_range)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	if result:
		var normal = result.normal
		direction = direction.slide(normal)
	
	return direction

# Play movement animation based on direction
func play_movement_animation(direction):
	if is_attacking or current_animation_state == "attack":
		return
	
	exit_idle_state()
	if velocity.length() > 0:
		current_animation_state = "move"
		
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				if not move_animation_enemy.is_playing() or move_animation_enemy.current_animation != "move_right":
					move_animation_enemy.play("move_right")
			else:
				if not move_animation_enemy.is_playing() or move_animation_enemy.current_animation != "move_left":
					move_animation_enemy.play("move_left")
		else:
			if direction.y > 0:
				if not move_animation_enemy.is_playing() or move_animation_enemy.current_animation != "move_down":
					move_animation_enemy.play("move_down")
			else:
				if not move_animation_enemy.is_playing() or move_animation_enemy.current_animation != "move_up":
					move_animation_enemy.play("move_up")
	else:
		current_animation_state = "idle"
		play_idle_animation()

# Play attack animation based on direction to player
func play_attack_animation():
	if not is_instance_valid(target):
		return

	current_animation_state = "attack"
	move_animation_enemy.stop()
	normal_sprite.hide()
	
	var direction = global_position.direction_to(target.global_position)
	var animation_name = "attack_right"
	
	if abs(direction.x) > abs(direction.y):
		animation_name = "attack_right" if direction.x > 0 else "attack_left"
	else:
		animation_name = "attack_down" if direction.y > 0 else "attack_up"
	
	attack_sprite.show()
	play_attack_sound()
	
	attack_animation_enemy.play(animation_name)
	await attack_animation_enemy.animation_finished
	
	normal_sprite.show()
	attack_sprite.hide()
	is_attacking = false
	current_animation_state = "idle"

# Coolddown the sound effect
func play_attack_sound():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_sound_time > ATTACK_SOUND_COOLDOWN:
		if attack_sound:
			attack_sound.play()
		last_attack_sound_time = current_time
		
# Take damage when hit by a bullet
func _on_hitbox_area_entered(area: Area2D):
	if area.is_in_group("Bullet"):
		take_damage(area.damage, area)

# Handle taking damage
func take_damage(damage: float, bullet = null):
	if is_dead:
		return

	if current_health == null:
		current_health = max_health

	current_health -= damage

	if bullet and ("has_fire_effect" in bullet) and bullet.has_fire_effect:
		apply_fire_effect()

	if current_health <= 0:
		current_health = 0
		die()
	else:
		play_hit_sound()
		flash_damage()
		show_damage(damage)
	
	if bullet:
		bullet.queue_free()
		
# Show damage number when hit
func show_damage(damage: float):
	var damage_label_scene = preload("res://UI/ui_scenes/damage_label.tscn")
	var damage_label = damage_label_scene.instantiate() as RichTextLabel
	damage_label.text = str(snappedf(damage, 0.1))
	
	if is_burning:
		damage_label.modulate = Color(1.5, 0.7, 0.2)
		
	damage_label.global_position = global_position + Vector2(0, -30)
	get_tree().root.add_child(damage_label)
	
func setup_fire_system():
	fire_timer = Timer.new()
	fire_timer.one_shot = true
	fire_timer.timeout.connect(stop_fire_effect)
	add_child(fire_timer)
	
	fire_tick_timer = Timer.new()
	fire_tick_timer.wait_time = fire_tick_time
	fire_tick_timer.timeout.connect(apply_fire_damage)
	add_child(fire_tick_timer)
	
	setup_fire_particles()

func setup_fire_particles():
	if not fire_particles:
		fire_particles = fire_particles_scene.instantiate()
		add_child(fire_particles)
		fire_particles.emitting = false

		var point_light = fire_particles.get_node("PointLight2D")
		point_light.enabled = false

func apply_fire_effect():
	if is_dead:
		return
	
	if burn_tween:
		burn_tween.kill()
	
	is_burning = true
	
	fire_particles.emitting = true
	burn_tween = create_tween()
	burn_tween.tween_property(normal_sprite, "modulate", Color(1.5, 0.7, 0.2), 0.3)
	
	fire_timer.start(fire_duration)
	if not fire_tick_timer.is_stopped():
		fire_tick_timer.stop()
	fire_tick_timer.start()

	var point_light = fire_particles.get_node("PointLight2D")
	point_light.enabled = true

func apply_fire_damage():
	if is_burning and not is_dead:
		var burn_damage = fire_damage
		
		show_damage(burn_damage)
		
		current_health -= burn_damage
		if current_health <= 0:
			current_health = 0
			die()
		else:
			var flash_tween = create_tween()
			flash_tween.tween_property(normal_sprite, "modulate",
				Color(2.0, 0.5, 0.0), 0.1)
			flash_tween.tween_property(normal_sprite, "modulate",
				Color(1.5, 0.7, 0.2), 0.2)

# Play hit sound with cooldown
func play_hit_sound():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_hit_sound_time > HIT_SOUND_COOLDOWN:
		hit_damage_sound.play()
		last_hit_sound_time = current_time

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
	if drop_chance < 0.9:
		var ammo_scene = preload("res://Interactables/Scenes/ammo_1.tscn")
		var ammo = ammo_scene.instantiate()
		ammo.global_position = global_position
		get_tree().root.call_deferred("add_child", ammo)
		
func stop_fire_effect():
	is_burning = false
	fire_particles.emitting = false

	var point_light = fire_particles.get_node("PointLight2D")
	point_light.enabled = false

	if burn_tween:
		burn_tween.kill()

	burn_tween = create_tween()
	burn_tween.tween_property(normal_sprite, "modulate", Color(1, 1, 1), 0.3)
		
func initialize_speed():
	var variation_percent = randf_range(-speed_variation, speed_variation) / 100.0
	speed = base_speed * (1 + variation_percent)
	speed = min(speed, max_allowed_speed)
	update_speed_with_slow()

func update_speed_with_slow():
	if power_up_manager:
		var slow_multiplier = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.ENEMY_SLOW)
		speed = base_speed * slow_multiplier
		
		if slow_multiplier < 1.0:
			apply_slow_effect()
		else:
			remove_slow_effect()

func apply_slow_effect():
	if not slow_effect_particles:
		setup_slow_particles()
	
	if slow_tween:
		slow_tween.kill()
	
	slow_tween = create_tween()
	slow_tween.tween_property(normal_sprite, "modulate",
		Color(0.7, 0.8, 1.0, 1.0), 0.3)
	
	slow_effect_particles.emitting = true

func remove_slow_effect():
	if slow_tween:
		slow_tween.kill()
	
	slow_tween = create_tween()
	slow_tween.tween_property(normal_sprite, "modulate",
		base_modulate, 0.3)
	
	if slow_effect_particles:
		slow_effect_particles.emitting = false

func setup_slow_particles():
	slow_effect_particles = GPUParticles2D.new()
	add_child(slow_effect_particles)
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 10.0
	particle_material.particle_flag_disable_z = true
	particle_material.gravity = Vector3(0, -20, 0)
	particle_material.initial_velocity_min = 2.0
	particle_material.initial_velocity_max = 5.0
	particle_material.orbit_velocity_min = 0.0
	particle_material.orbit_velocity_max = 0.0
	particle_material.damping_min = 1.0
	particle_material.damping_max = 2.0
	particle_material.scale_min = 2.0
	particle_material.scale_max = 4.0
	particle_material.color = Color(0.7, 0.8, 1.0, 0.5)
	
	slow_effect_particles.process_material = particle_material
	slow_effect_particles.amount = 15
	slow_effect_particles.lifetime = 1.0
	slow_effect_particles.explosiveness = 0.0
	slow_effect_particles.randomness = 0.5
	slow_effect_particles.fixed_fps = 30

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
		
