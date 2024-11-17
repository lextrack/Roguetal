extends CharacterBody2D

enum player_states {MOVE, DEAD}

const MAGNET_RADIUS = 100.0
const MAX_HEAT = 100.0
const HEAT_COOLDOWN = 30.0
const OVERHEAT_PENALTY_TIME = 1.3
const CONFIG_PATH = "user://options_settings.cfg"
const DEFAULT_SENSITIVITY = 1.0

@export var contact_damage = 0.02
@export var speed: int
@export var base_speed: int
@export var walk_sound_interval = 0.4
@export var rapid_shoot_delay: float = 0.1
@export var bazooka_shoot_delay: float = 0.6
@export var damage_interval = 0.1
@export var gamepad_deadzone: float = 0.1

@onready var bullet_scenes = {
	"bazooka": preload("res://Entities/Scenes/Bullets/bullet_1.tscn"),
	"m16": preload("res://Entities/Scenes/Bullets/bullet_rapid.tscn"),
	"shotgun": preload("res://Entities/Scenes/Bullets/bullet_shotgun.tscn"),
}
@onready var shell_textures = {
	"m16": preload("res://Sprites/bullet-casings_m16.png"),
	"shotgun": preload("res://Sprites/shotgun_shell.png")
}

@onready var trail_scene = preload("res://Entities/Scenes/FX/scent_trail.tscn")
@onready var weapons_container = $weapons_container
@onready var sprite = $Sprite2D
@onready var walk_sound_player = $Sounds/WalkSoundPlayer
@onready var cursor_script = $mouse_icon
@onready var audio_stream_shotgun_shot: AudioStreamPlayer2D = $Sounds/AudioStreamShotgunShot
@onready var audio_stream_dead_player: AudioStreamPlayer2D = $Sounds/AudioStreamDeadPlayer
@onready var damage_timer: Timer = $Timers/damage_timer
@onready var magnet_area: Area2D = $MagnetArea
@onready var tween: Tween
@onready var hud_powerup: Node2D = $ControlPowerUpHud/hud_powerup
@onready var double_speed_icon: Sprite2D = $ControlPowerUpHud/hud_powerup/double_speed_icon
@onready var double_damage_icon: Sprite2D = $ControlPowerUpHud/hud_powerup/double_damage_icon
@onready var double_defense_icon: Sprite2D = $ControlPowerUpHud/hud_powerup/double_defense_icon
@onready var bullet_hell_icon: Sprite2D = $ControlPowerUpHud/hud_powerup/bullet_hell_icon
@onready var critical_icon: Sprite2D = $ControlPowerUpHud/hud_powerup/critical_icon
@onready var slow_enemies_icon: Sprite2D = $ControlPowerUpHud/hud_powerup/slow_enemies_icon
@onready var power_up_manager = $PowerUpManager
@onready var point_light: PointLight2D = $PointLight2D
@onready var audio_stream_weapon_switch: AudioStreamPlayer2D = $Sounds/AudioStreamWeaponSwitch
@onready var smoke_particles_scene = preload("res://Entities/Scenes/FX/smoke_particles.tscn")
@onready var shotgun_shell_incendiary_icon: Sprite2D = $ControlPowerUpHud/hud_powerup/shotgun_shell_incendiary_icon

var current_state = player_states.MOVE
var heat_level = 0.0
var is_overheated = false
var overheat_timer = 0.0
var light_transition_tween: Tween
var is_weapon_switching = false
var light_disabled_by_timer = false
var is_dead = false
var is_using_gamepad = false
var last_input_time = 0.0
var walk_sound_timer = 0.0
var shoot_timer: float = 0.0
var is_in_portal = false
var is_flashing = false
var enemies_in_contact = 0
var rot
var input_movement = Vector2()
var weapons = []
var current_weapon_index = 0
var weapon_damage = {
	"bazooka": 5,
	"m16": 3,
	"shotgun": 2
}

func _ready() -> void:
	if power_up_manager:
		print("PowerUpManager initialized successfully")
	else:
		print("PowerUpManager not found")
		
	weapons = weapons_container.get_children()
	setup_weapons()
	update_visible_weapon()
	check_level_and_set_weapon()
	
	damage_timer.wait_time = damage_interval
	damage_timer.one_shot = false
	setup_double_damage_icon()
	
	setup_double_speed_icon()
	base_speed = speed
	
	setup_bullet_hell_icon()
	setup_double_defense_icon()
	setup_critical_icon()
	setup_shotgun_shell_incendiary_icon()
	setup_slow_enemies_icon()
	
	setup_magnet_area()
	add_to_group("player")
	
	power_up_manager_check()
	light_disabled_by_timer = false
	update_light_state()
	display_HUD_while_using_directionalight()
	
	if point_light:
		point_light.energy = 1.0

func _process(delta: float) -> void:
	if player_data.health <= 0 and current_state != player_states.DEAD:
		current_state = player_states.DEAD
		dead()
	else:
		detect_input_device()
		if not is_using_gamepad:
			target_mouse()
		joystick_aiming(delta)
		movement(delta)
		bullet_type_shooting(delta)
		handle_weapon_switch()
		
func power_up_manager_check() -> void:
	if power_up_manager:
		power_up_manager.connect("power_up_changed", Callable(self, "_on_power_up_changed"))
	else:
		push_error("PowerUpManager not found.")

	for type in PowerUpTypes.PowerUpType.values():
		_on_power_up_changed(type, power_up_manager.get_multiplier(type))

func _on_power_up_changed(type: int, multiplier: float) -> void:
	match type:
		PowerUpTypes.PowerUpType.DAMAGE:
			update_double_damage_icon(multiplier)
		PowerUpTypes.PowerUpType.SPEED:
			speed = base_speed * multiplier
			update_double_speed_icon(multiplier)
		PowerUpTypes.PowerUpType.DEFENSE:
			update_double_defense_icon(multiplier)
		PowerUpTypes.PowerUpType.BULLET_HELL:
			update_bullet_hell_icon(multiplier)
		PowerUpTypes.PowerUpType.CRITICAL_CHANCE:
			update_critical_icon(multiplier)
		PowerUpTypes.PowerUpType.ENEMY_SLOW:
			update_slow_enemies_icon(multiplier)
		PowerUpTypes.PowerUpType.SHOTGUN_FIRE:
			update_shotgun_shell_incendiary_icon(multiplier)

func update_double_defense_icon(multiplier: float):
	if double_defense_icon:
		double_defense_icon.visible = multiplier > 1.0

func update_double_damage_icon(multiplier: float):
	if double_damage_icon:
		double_damage_icon.visible = multiplier > 1.0

func update_double_speed_icon(multiplier: float):
	if double_speed_icon:
		double_speed_icon.visible = multiplier > 1.0

func update_bullet_hell_icon(multiplier: float):
	if bullet_hell_icon:
		bullet_hell_icon.visible = multiplier >= 1.0

func setup_double_defense_icon():
	if double_defense_icon:
		double_defense_icon.visible = false

func setup_double_damage_icon():
	if double_damage_icon:
		double_damage_icon.visible = false

func setup_double_speed_icon():
	if double_speed_icon:
		double_speed_icon.visible = false

func setup_bullet_hell_icon():
	if bullet_hell_icon:
		bullet_hell_icon.visible = false
		
func setup_critical_icon():
	if critical_icon:
		critical_icon.visible = false

func update_critical_icon(multiplier: float):
	if critical_icon:
		critical_icon.visible = multiplier > 1.0
		
func setup_slow_enemies_icon():
	if slow_enemies_icon:
		slow_enemies_icon.visible = false

func update_slow_enemies_icon(multiplier: float):
	if slow_enemies_icon:
		slow_enemies_icon.visible = multiplier < 1.0
		
func setup_shotgun_shell_incendiary_icon():
	if shotgun_shell_incendiary_icon:
		shotgun_shell_incendiary_icon.visible = false
	else:
		print("Shotgun icon not found!")

func update_shotgun_shell_incendiary_icon(multiplier: float):
	if shotgun_shell_incendiary_icon:
		shotgun_shell_incendiary_icon.visible = multiplier >= 1.0
	else:
		print("Cannot update shotgun icon - node not found!")
	
func setup_magnet_area():
	if not magnet_area:
		push_error("MagnetArea node not found.")
		return
	
	if not magnet_area.is_connected("area_entered", Callable(self, "_on_magnet_area_area_entered")):
		magnet_area.connect("area_entered", Callable(self, "_on_magnet_area_area_entered"))
	
	var collision_shape = magnet_area.get_node("CollisionShape2D")
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = MAGNET_RADIUS

func _on_magnet_area_area_entered(area: Area2D):
	if area.is_in_group("ammo") and area.has_method("start_attraction"):
		area.start_attraction(self)

func get_mouse_sensitivity() -> float:
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		return config.get_value("controls", "mouse_sensitivity", DEFAULT_SENSITIVITY)
	return DEFAULT_SENSITIVITY

func detect_input_device() -> void:
	var gamepad_input = _get_total_gamepad_input()
	var mouse_movement = Input.get_last_mouse_velocity()
	
	if gamepad_input > gamepad_deadzone:
		_switch_to_gamepad(true)
	elif mouse_movement.length() > 0:
		_switch_to_gamepad(false)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _get_total_gamepad_input() -> float:
	return abs(Input.get_action_strength("rs_right")) + \
		abs(Input.get_action_strength("rs_left")) + \
		abs(Input.get_action_strength("rs_up")) + \
		abs(Input.get_action_strength("rs_down"))

func _switch_to_gamepad(use_gamepad: bool) -> void:
	is_using_gamepad = use_gamepad
	cursor_script.is_using_gamepad = use_gamepad
	if use_gamepad:
		last_input_time = Time.get_ticks_msec()

func target_mouse() -> void:
	if _can_update_aim():
		var mouse_pos = get_global_mouse_position()
		_update_weapon_rotation((mouse_pos - global_position).angle())

func joystick_aiming(delta: float) -> void:
	if _can_update_aim() and is_using_gamepad:
		var direction = _get_joystick_direction()
		if direction.length() > gamepad_deadzone:
			_update_weapon_rotation(direction.angle())

func _get_joystick_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("rs_right") - Input.get_action_strength("rs_left"),
		Input.get_action_strength("rs_down") - Input.get_action_strength("rs_up")
	)

func _can_update_aim() -> bool:
	return not is_dead and weapons_container.visible

func _update_weapon_rotation(angle: float) -> void:
	weapons_container.rotation = angle
	rot = rad_to_deg(angle)
	update_weapon_flip()

func update_visible_weapon() -> void:
	for i in weapons.size():
		weapons[i].visible = (i == current_weapon_index)
		if i == current_weapon_index:
			weapons[i].scale = Vector2.ONE
			weapons[i].rotation_degrees = 0

func update_weapon_flip() -> void:
	var gun_sprite = weapons[current_weapon_index].get_node("gun_sprite")
	var should_flip = not (rot >= -90 and rot <= 90)
	gun_sprite.flip_v = should_flip
	sprite.flip_h = should_flip
	
func dead() -> void:
	if not is_dead:
		is_dead = true
		
		var current_scene = get_tree().current_scene.scene_file_path
		EnemyScalingManagerGlobal.register_player_death(current_scene)
		
		stop_all_attractions()
		
		if magnet_area:
			magnet_area.monitoring = false
			magnet_area.monitorable = false
		
		velocity = Vector2.ZERO
		weapons_container.visible = false
		audio_stream_dead_player.play()
		$player_animation.play("Dead")

		player_data.ammo += 30
		player_data.kill_count = 0
		player_data.reset_kill_streak()
		
		if power_up_manager:
			power_up_manager.reset_power_ups()

func check_level_and_set_weapon() -> void:
	var current_scene = get_tree().current_scene
	var visible_levels = ["main_dungeon", "main_dungeon_2", "labyrinth_level"]
	
	if current_scene.name in visible_levels:
		weapons_container.visible = true
	else:
		weapons_container.visible = false
		update_animation_without_gun()

func update_animation_without_gun() -> void:
	if input_movement != Vector2.ZERO:
		if not $player_animation.is_playing() or $player_animation.current_animation != "Move":
			$player_animation.play("Move")
	else:
		if not $player_animation.is_playing() or $player_animation.current_animation != "Idle":
			$player_animation.play("Idle")

func animation() -> void:
	if is_dead:
		if not $player_animation.is_playing() or $player_animation.current_animation != "Dead":
			$player_animation.play("Dead")
	elif input_movement != Vector2.ZERO:
		if not $player_animation.is_playing() or $player_animation.current_animation != "Move":
			$player_animation.play("Move")
	else:
		if not $player_animation.is_playing() or $player_animation.current_animation != "Idle":
			$player_animation.play("Idle")

func movement(delta: float) -> void:
	if current_state == player_states.DEAD:
		return
	
	input_movement = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_movement != Vector2.ZERO:
		input_movement = input_movement.normalized()
		input_movement = Vector2(round(input_movement.x), round(input_movement.y))
		
		velocity = input_movement * speed
		
		if input_movement.x < 0:
			sprite.flip_h = true
		elif input_movement.x > 0:
			sprite.flip_h = false
	else:
		velocity = Vector2.ZERO
		
	animation()

	if input_movement != Vector2.ZERO:
		walk_sound_timer -= delta
		if walk_sound_timer <= 0:
			walk_sound_player.play()
			walk_sound_timer = walk_sound_interval
	else:
		walk_sound_timer = 0
	
	move_and_slide()
			
func apply_recoil(weapon: Node2D, bullet_type: String):
	var recoil_distance = 0.0
	var recoil_duration = 0.0
	
	match bullet_type:
		"bazooka":
			recoil_distance = 20.0
			recoil_duration = 0.2
		"shotgun":
			recoil_distance = 15.0
			recoil_duration = 0.15
		"m16":
			recoil_distance = 5.0
			recoil_duration = 0.05
	
	var direction = Vector2.LEFT.rotated(weapon.rotation)
	var original_pos = weapon.position
	
	var tween = create_tween()
	tween.tween_property(weapon, "position",
		weapon.position + direction * recoil_distance,
		recoil_duration * 0.25)
	tween.tween_property(weapon, "position",
		original_pos,
		recoil_duration * 0.75)

func create_muzzle_flash(weapon: Node2D, flash_color: Color, size: float):
	var bullet_point = weapon.get_node("bullet_point")
	var flash = Sprite2D.new()
	flash.texture = preload("res://Sprites/muzzle_flash.png")
	flash.position = bullet_point.position
	flash.scale = Vector2(size, size)
	flash.modulate = flash_color
	weapon.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.1)
	tween.tween_callback(flash.queue_free)

func create_shell_casing(weapon: Node2D, type: String):
	var bullet_point = weapon.get_node("bullet_point")
	var shell = Sprite2D.new()
	
	shell.texture = shell_textures[type]
	
	var settings = {
		"m16": {
			"scale": Vector2(0.4, 0.4),
			"force": 25,
			"arc_height": 15,
			"rotation_speed": PI,
			"lifetime": 0.4,
			"fade_delay": 0.2,
			"eject_angle": -60
		},
		"shotgun": {
			"scale": Vector2(0.6, 0.6),
			"force": 35,
			"arc_height": 25,
			"rotation_speed": PI/2,
			"lifetime": 0.5,
			"fade_delay": 0.3,
			"eject_angle": -45
		}
	}
	
	var config = settings[type]
	
	shell.global_position = bullet_point.global_position
	shell.scale = config["scale"]
	get_tree().root.add_child(shell)
	
	var base_angle = deg_to_rad(config["eject_angle"])
	var eject_direction = Vector2.RIGHT.rotated(base_angle)
	eject_direction = eject_direction.rotated(weapon.global_rotation)
	
	var final_position = shell.global_position + (eject_direction * config["force"])
	final_position.y += config["arc_height"] * 0.5
	
	var mid_position = shell.global_position + (eject_direction * config["force"] * 0.5)
	mid_position.y -= config["arc_height"]
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_method(
		func(progress: float):
			var pos1 = shell.global_position.lerp(mid_position, progress)
			var pos2 = mid_position.lerp(final_position, progress)
			shell.global_position = pos1.lerp(pos2, progress),
		0.0, 1.0, config["lifetime"]
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if type == "m16":
		tween.tween_property(shell, "rotation",
			randf_range(2 * PI, 4 * PI),
			config["lifetime"])
	else:
		tween.tween_property(shell, "rotation",
			PI/2,
			config["lifetime"])
	
	tween.tween_property(shell, "modulate:a",
		0.0,
		0.2).set_delay(config["fade_delay"])
	
	tween.tween_callback(shell.queue_free).set_delay(config["lifetime"])
			
func instance_bullet():
	var current_weapon = weapons[current_weapon_index]
	var bullet_type = current_weapon.get_meta("bullet_type", "bazooka")
	
	apply_recoil(current_weapon, bullet_type)
	
	var bullet_scene = bullet_scenes.get(bullet_type, bullet_scenes["bazooka"])
	
	var damage_multiplier = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.DAMAGE)
	var bullet_hell_active = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.BULLET_HELL) >= 1.0
	
	var bullet_point = current_weapon.get_node("bullet_point")
	var base_direction = (bullet_point.global_position - weapons_container.global_position).normalized()
	
	var bullets_fired = 0
	
	match bullet_type:
		"bazooka":
			create_muzzle_flash(current_weapon, Color(1, 0.7, 0.2), 1.2)
			Globals.camera.screen_shake(1.5, 0.25, 0.1)
		"shotgun":
			create_muzzle_flash(current_weapon, Color(1, 1, 0.5), 0.8)
			create_shell_casing(current_weapon, "shotgun")
			Globals.camera.screen_shake(1.0, 0.2, 0.1)
		"m16":
			create_muzzle_flash(current_weapon, Color(1, 1, 1), 0.5)
			create_shell_casing(current_weapon, "m16")
			Globals.camera.screen_shake(0.3, 0.08, 0.2)
	
	if bullet_hell_active:
		bullets_fired = instance_bullet_hell(bullet_scene, bullet_point.global_position, damage_multiplier)
		Globals.camera.screen_shake(1.2, 0.2, 0.1)
	elif bullet_type == "shotgun":
		bullets_fired = instance_shotgun(bullet_scene, bullet_point.global_position, base_direction, damage_multiplier)
	else:
		bullets_fired = instance_single_bullet(bullet_scene, bullet_point.global_position, base_direction, damage_multiplier, bullet_type)
		
	return bullets_fired
			
func instance_bullet_hell(bullet_scene: PackedScene, spawn_position: Vector2, damage_multiplier: float) -> int:
	var num_bullets = 5
	
	var has_fire = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.SHOTGUN_FIRE) >= 1.0
	var current_weapon = weapons[current_weapon_index]
	var bullet_type = current_weapon.get_meta("bullet_type", "bazooka")
	
	var crit_multiplier = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.CRITICAL_CHANCE)
	var crit_chance = (crit_multiplier - 1.0) * 100
	var is_critical = randf() * 100 <= crit_chance
	
	if has_fire and bullet_type == "shotgun":
		create_muzzle_flash(current_weapon, Color(1.5, 0.5, 0.2), 1.0)
	
	for i in range(num_bullets):
		var angle = 2 * PI * i / num_bullets
		var direction = Vector2(cos(angle), sin(angle))
		
		var bullet = bullet_scene.instantiate()
		var final_damage = weapon_damage[bullet_type] * damage_multiplier
		
		if is_critical:
			final_damage *= 2.0
			apply_critical_effect(bullet, bullet_type)
		
		if has_fire and bullet_type == "shotgun":
			bullet.has_fire_effect = true
			if is_critical:
				bullet.modulate = Color(2.0, 0.5, 0.0)
			else:
				bullet.modulate = Color(1.5, 0.7, 0.2)
		
		bullet.damage = final_damage
		bullet.direction = direction
		bullet.global_position = spawn_position
		get_tree().root.add_child(bullet)
	
	if has_fire and bullet_type == "shotgun":
		if is_critical:
			$Sounds/AudioStreamShotgunShot.pitch_scale = 0.8
			$Sounds/AudioStreamShotgunShot.volume_db += 2
		else:
			$Sounds/AudioStreamShotgunShot.pitch_scale = 0.9
		$Sounds/AudioStreamShotgunShot.play()
		
		var reset_timer = Timer.new()
		add_child(reset_timer)
		reset_timer.wait_time = 0.1
		reset_timer.one_shot = true
		reset_timer.timeout.connect(func():
			$Sounds/AudioStreamShotgunShot.pitch_scale = 1.0
			$Sounds/AudioStreamShotgunShot.volume_db = 0
			reset_timer.queue_free()
		)
		reset_timer.start()
	
	return num_bullets
	
func instance_shotgun(bullet_scene: PackedScene, spawn_position: Vector2, base_direction: Vector2, damage_multiplier: float) -> int:
	var num_pellets = 4
	
	var crit_multiplier = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.CRITICAL_CHANCE)
	var crit_chance = (crit_multiplier - 1.0) * 100
	var is_critical = randf() * 100 <= crit_chance
	
	var has_fire = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.SHOTGUN_FIRE) >= 1.0
	
	if is_critical:
		Globals.camera.screen_shake(1.2, 0.2, 0.1)
		
		var current_weapon = weapons[current_weapon_index]
		if current_weapon.has_node("gun_sprite"):
			var gun_sprite = current_weapon.get_node("gun_sprite")
			var tween = create_tween()
			tween.tween_property(gun_sprite, "modulate",
				Color(2.0, 1.5, 0.0, 1.0), 0.1)
			tween.tween_property(gun_sprite, "modulate",
				Color(1.0, 1.0, 1.0, 0.2), 0.2)
	
	if has_fire:
		var current_weapon = weapons[current_weapon_index]
		create_muzzle_flash(current_weapon, Color(1.5, 0.5, 0.2), 1.0)
	
	for i in range(num_pellets):
		var bullet = bullet_scene.instantiate()
		# Convertir el daño base a float explícitamente
		var base_damage = float(weapon_damage["shotgun"])
		var final_damage = base_damage * damage_multiplier
		
		if is_critical:
			final_damage *= 2.0
			apply_critical_effect(bullet, "shotgun")
			bullet.base_speed = 300
			bullet.speed_variation = 30
		else:
			bullet.base_speed = 250
			bullet.speed_variation = 50
		
		if has_fire:
			bullet.has_fire_effect = true
			if is_critical:
				bullet.modulate = Color(2.0, 0.5, 0.0)
			else:
				bullet.modulate = Color(1.5, 0.7, 0.2)
		
		bullet.damage = final_damage
		bullet.direction = base_direction
		bullet.global_position = spawn_position
		bullet.start_delay_max = 0.05
		get_tree().root.add_child(bullet)
	
	if has_fire:
		if is_critical:
			$Sounds/AudioStreamShotgunShot.pitch_scale = 0.8
			$Sounds/AudioStreamShotgunShot.volume_db += 2
		else:
			$Sounds/AudioStreamShotgunShot.pitch_scale = 0.9
		$Sounds/AudioStreamShotgunShot.play()
		
		var reset_timer = Timer.new()
		add_child(reset_timer)
		reset_timer.wait_time = 0.1
		reset_timer.one_shot = true
		reset_timer.timeout.connect(func():
			$Sounds/AudioStreamShotgunShot.pitch_scale = 1.0
			$Sounds/AudioStreamShotgunShot.volume_db = 0
			reset_timer.queue_free()
		)
		reset_timer.start()
	else:
		$Sounds/AudioStreamShotgunShot.play()
	
	return num_pellets

func instance_single_bullet(bullet_scene: PackedScene, spawn_position: Vector2, direction: Vector2, damage_multiplier: float, bullet_type: String) -> int:
	var bullet = bullet_scene.instantiate()
	
	var crit_multiplier = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.CRITICAL_CHANCE)
	var crit_chance = (crit_multiplier - 1.0) * 100
	var is_critical = randf() * 100 <= crit_chance
	
	# Convertir el daño base a float explícitamente y aplicar el multiplicador
	var base_damage = float(weapon_damage[bullet_type])
	var final_damage = base_damage * damage_multiplier
	
	if is_critical:
		final_damage *= 2.0
		apply_critical_effect(bullet, bullet_type)
		
		Globals.camera.screen_shake(0.8, 0.15, 0.1)
		
		var current_weapon = weapons[current_weapon_index]
		if current_weapon.has_node("gun_sprite"):
			var gun_sprite = current_weapon.get_node("gun_sprite")
			var tween = create_tween()
			tween.tween_property(gun_sprite, "modulate",
				Color(2.0, 1.5, 0.0, 1.0), 0.1)
			tween.tween_property(gun_sprite, "modulate",
				Color(1.0, 1.0, 1.0, 1.0), 0.2)
	
	bullet.damage = final_damage
	bullet.direction = direction
	bullet.global_position = spawn_position
	
	match bullet_type:
		"m16":
			bullet.speed = 400 if is_critical else 300
		"bazooka":
			if is_critical:
				bullet.explosion_radius = bullet.explosion_radius * 1.2
				bullet.speed = bullet.speed * 1.1
	
	get_tree().root.add_child(bullet)
	
	if bullet_type == "bazooka":
		$Sounds/AudioStreamBazookaShot.play()
	elif bullet_type == "m16":
		$Sounds/AudioStreamM16Shot.play()
	
	return 1

func apply_critical_effect(bullet: Node2D, bullet_type: String) -> void:
	var crit_color = Color(1.5, 1.0, 0.0, 1.0)
	var crit_scale = Vector2(1.2, 1.2)
	
	match bullet_type:
		"m16":
			bullet.modulate = Color(1.3, 1.0, 0.0, 1.0)
			bullet.scale = Vector2(1.6, 1.6)
		
			if bullet.has_node("GPUParticles2D"):
				var particles = bullet.get_node("GPUParticles2D")
				particles.modulate = Color(1.5, 1.2, 0.0, 1.0)
				particles.amount = particles.amount * 1.5
				
		"bazooka":
			bullet.modulate = crit_color
			bullet.scale = crit_scale
			
			if bullet.has_node("GPUParticles2D"):
				var particles = bullet.get_node("GPUParticles2D")
				particles.modulate = Color(1.5, 1.0, 0.0, 1.0)
				particles.amount = particles.amount * 2
				
		"shotgun":
			bullet.modulate = Color(1.4, 1.0, 0.0, 1.0)
			bullet.scale = Vector2(1.15, 1.15)

func bullet_type_shooting(delta: float):
	var current_weapon = weapons[current_weapon_index]
	var bullet_type = current_weapon.get_meta("bullet_type", "bazooka")

	if is_overheated:
		overheat_timer -= delta
		if overheat_timer <= 0:
			is_overheated = false
			heat_level = 0.0

	if not is_overheated:
		heat_level = max(0.0, heat_level - HEAT_COOLDOWN * delta)
	
	update_weapon_heat_effect(current_weapon, heat_level / MAX_HEAT)

	if not is_overheated and Input.is_action_pressed("ui_shoot") and player_data.ammo > 0 and weapons_container.visible:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			var bullets_fired = instance_bullet()
			player_data.ammo -= bullets_fired
			
			match bullet_type:
				"bazooka":
					add_heat(20)
				"shotgun":
					add_heat(35)
				"m16":
					add_heat(5)
			
			if player_data.ammo < 0:
				player_data.ammo = 0
			
			if bullet_type == "m16":
				shoot_timer = rapid_shoot_delay
			elif bullet_type == "shotgun":
				shoot_timer = 1.0
			else:
				shoot_timer = bazooka_shoot_delay

func add_heat(amount: float):
	heat_level = min(MAX_HEAT, heat_level + amount)
	
	if heat_level >= MAX_HEAT:
		trigger_overheat()

func trigger_overheat():
	is_overheated = true
	overheat_timer = OVERHEAT_PENALTY_TIME
	
	var current_weapon = weapons[current_weapon_index]
	if current_weapon.has_node("gun_sprite"):
		var gun_sprite = current_weapon.get_node("gun_sprite")
		
		var tween = create_tween()
		tween.tween_property(gun_sprite, "modulate",
			Color(2.0, 0.0, 0.0, 1.0), 0.1)
		tween.tween_property(gun_sprite, "modulate",
			Color(1.0, 0.0, 0.0, 1.0), 0.1)

		create_overheat_smoke(current_weapon)

func create_overheat_smoke(weapon: Node2D):
	var bullet_point = weapon.get_node("bullet_point")
	var smoke = smoke_particles_scene.instantiate()
	weapon.add_child(smoke)
	smoke.position = bullet_point.position
	
	var tween = create_tween()
	tween.tween_callback(func():
		smoke.emitting = false
	).set_delay(OVERHEAT_PENALTY_TIME)
	
	tween.tween_callback(func():
		smoke.queue_free()
	).set_delay(1.0)

func update_weapon_heat_effect(weapon: Node2D, heat_ratio: float):
	if weapon.has_node("gun_sprite"):
		var gun_sprite = weapon.get_node("gun_sprite")
		if not is_overheated:
			var heat_color = Color(
				1.0 + heat_ratio * 0.5,
				1.0 - heat_ratio * 0.5,
				1.0 - heat_ratio * 0.5,
				1.0
			)
			gun_sprite.modulate = heat_color
		else:
			var pulse = (1.0 + sin(Time.get_ticks_msec() * 0.01)) * 0.5
			var overheat_color = Color(
				1.0 + pulse * 0.5,
				0.2,
				0.2,
				1.0
			)
			gun_sprite.modulate = overheat_color

func setup_weapons():
	for i in range(weapons.size()):
		var weapon = weapons[i]
		if i == 0:
			weapon.set_meta("bullet_type", "bazooka")
		elif i == 1:
			weapon.set_meta("bullet_type", "m16")
		elif i == 2:
			weapon.set_meta("bullet_type", "shotgun")

func handle_weapon_switch():
	if Input.is_action_just_pressed("switch_weapon"):
		switch_weapon()

func switch_weapon():
	if is_weapon_switching:
		return
		
	is_weapon_switching = true
	current_weapon_index = (current_weapon_index + 1) % weapons.size()
	
	if has_node("Sounds/AudioStreamWeaponSwitch"):
		$Sounds/AudioStreamWeaponSwitch.play()
	else:
		var weapon_switch_player = AudioStreamPlayer2D.new()
		weapon_switch_player.name = "AudioStreamWeaponSwitch"
		$Sounds.add_child(weapon_switch_player)
		
		var weapon_switch_sound = preload("res://SoundEffects/switch_weapons.ogg")
		weapon_switch_player.stream = weapon_switch_sound
		weapon_switch_player.volume_db = 0.0
		weapon_switch_player.play()
	
	var current_weapon = weapons[current_weapon_index]
	
	var tween = create_tween().set_parallel()
	
	tween.tween_property(current_weapon, "rotation_degrees", 360, 0.3).from(0)
	
	tween.tween_property(current_weapon, "scale", Vector2(1, 1), 0.3)\
		.from(Vector2(0.5, 0.5))\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	if current_weapon.has_node("gun_sprite"):
		var gun_sprite = current_weapon.get_node("gun_sprite")
		gun_sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
		tween.tween_property(gun_sprite, "modulate", Color(1, 1, 1, 1), 0.3)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func():
		is_weapon_switching = false
		update_visible_weapon()
	)

func take_damage(damage: float):
	if not is_in_portal:
		var defense_multiplier = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.DEFENSE)
		var reduced_damage = damage / defense_multiplier
		player_data.health -= reduced_damage
		if not is_flashing:
			flash_damage()
		if player_data.health <= 0:
			dead()
			if magnet_area:
				magnet_area.monitoring = false
				magnet_area.monitorable = false
				
func increase_health(amount: int) -> void:
	player_data.health += amount
	if player_data.health > 4:
		player_data.health = 4

func stop_all_attractions():
	var ammo_items = get_tree().get_nodes_in_group("ammo")
	for item in ammo_items:
		if item.has_method("stop_attraction"):
			item.stop_attraction()

func reset_state():
	current_state = player_states.MOVE
	
func update_light_state() -> void:
	if point_light:
		var current_scene = get_tree().current_scene
		if current_scene and current_scene.name == "labyrinth_level":
			if not light_disabled_by_timer:
				enable_light()
			else:
				point_light.enabled = false
				point_light.energy = 0.0
		else:
			point_light.enabled = false
			point_light.energy = 0.0
	else:
		print("point_light node not found")
	
func disable_light() -> void:
	if point_light and get_tree().current_scene.name == "labyrinth_level":
		if light_transition_tween and light_transition_tween.is_valid():
			light_transition_tween.kill()
		
		light_transition_tween = create_tween()
		light_transition_tween.set_trans(Tween.TRANS_SINE)
		light_transition_tween.set_ease(Tween.EASE_OUT)
		
		light_transition_tween.tween_property(point_light, "energy", 0.0, 1.0)

		light_transition_tween.tween_callback(func():
			point_light.enabled = false
			light_disabled_by_timer = true
		)
	else:
		print("Could not disable light. point_light exists: ", point_light != null, " scene name: ", get_tree().current_scene.name)

func enable_light() -> void:
	if point_light:
		if light_transition_tween and light_transition_tween.is_valid():
			light_transition_tween.kill()
		
		point_light.enabled = true
		point_light.energy = 0.0
		
		light_transition_tween = create_tween()
		light_transition_tween.set_trans(Tween.TRANS_SINE)
		light_transition_tween.set_ease(Tween.EASE_IN)
		
		light_transition_tween.tween_property(point_light, "energy", 1.0, 0.5)
		light_disabled_by_timer = false
		
func enter_portal(portal_type: String = ""):
	is_in_portal = true
	
	if light_transition_tween and light_transition_tween.is_valid():
		light_transition_tween.kill()
	
	if portal_type == "exit_portal":
		if power_up_manager:
			power_up_manager.handle_level_transition("main_world")
	elif portal_type == "next_level":
		light_disabled_by_timer = false
		update_light_state()
		var level_node = get_tree().get_root().get_node_or_null("Level")
		if level_node and level_node.has_node("timer_light_level"):
			level_node.get_node("timer_light_level").stop()
		
		var current_scene = get_tree().current_scene
		var dungeon_levels = ["main_dungeon", "main_dungeon_2", "labyrinth_level"]
		
		if current_scene.name in dungeon_levels:
			if power_up_manager:
				power_up_manager.handle_level_transition(current_scene.name)
		else:
			if power_up_manager:
				power_up_manager.handle_level_transition("main_dungeon")
				
func display_HUD_while_using_directionalight():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "UILayer"
	canvas_layer.layer = 1
	
	var control_power_up_hud = $ControlPowerUpHud
	var stats_window = $StatsWindow
	
	if control_power_up_hud:
		control_power_up_hud.get_parent().remove_child(control_power_up_hud)
	if stats_window:
		stats_window.get_parent().remove_child(stats_window)
	
	add_child(canvas_layer)
	
	if control_power_up_hud:
		canvas_layer.add_child(control_power_up_hud)
	if stats_window:
		canvas_layer.add_child(stats_window)
		
	if control_power_up_hud:
		_set_node_light_mask_recursive(control_power_up_hud, 2)
	if stats_window:
		_set_node_light_mask_recursive(stats_window, 2)
	
func _set_node_light_mask_recursive(node: Node, mask: int) -> void:
	if node is CanvasItem:
		node.light_mask = mask
	
	for child in node.get_children():
		_set_node_light_mask_recursive(child, mask)

func exit_portal():
	is_in_portal = false

func instance_trail():
	var trail = trail_scene.instantiate()
	trail.global_position = global_position
	get_tree().root.add_child(trail)
	
func flash_damage():
	if is_flashing:
		return
	
	is_flashing = true
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0.7)
	
	var flash_duration = 0.2
	var fade_duration = 0.1
	
	await get_tree().create_timer(flash_duration).timeout
	
	var tween_instance = create_tween()
	tween_instance.tween_property($Sprite2D.material, "shader_parameter/flash_modifier", 0.0, fade_duration)
	tween_instance.tween_callback(func(): is_flashing = false)

func _on_anim_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Dead":
		var highest_streak = player_data.highest_kill_streak
		player_data.reset_stats()
		player_data.highest_kill_streak = highest_streak
		if power_up_manager:
			power_up_manager.reset_power_ups()
		get_tree().reload_current_scene()

func _on_trail_timer_timeout() -> void:
	instance_trail()
	$Timers/trail_timer.start()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") and not is_in_portal:
		enemies_in_contact += 1

func _on_hitbox_area_exited(area: Area2D) -> void:
	pass
