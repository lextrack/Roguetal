# PLAYER SCRIPT

extends CharacterBody2D

enum player_states {MOVE, DEAD}
var pos
var rot
var input_movement = Vector2()
var current_state = player_states.MOVE
var is_dead = false
var is_using_gamepad = false
var last_input_time = 0.0
var gamepad_deadzone = 0.1
var walk_sound_timer = 0.0
var shoot_timer: float = 0.0
var is_in_portal = false
var is_flashing = false
var enemies_in_contact = 0

var double_damage_active = false
var double_damage_timer = 0.0
const DOUBLE_DAMAGE_DURATION = 10.0  # Duración del efecto de doble daño en segundos

@export var contact_damage = 0.1  # Daño recibido por contacto con enemigos
@export var speed: int  # Velocidad de movimiento del jugador
@export var walk_sound_interval = 0.4  # Intervalo entre sonidos de pasos
@export var rapid_shoot_delay: float = 0.1
@export var bazooka_shoot_delay: float = 0.5

@onready var bullet_scenes = {
	"bazooka": preload("res://Entities/Scenes/Bullets/bullet_1.tscn"),
	"m16": preload("res://Entities/Scenes/Bullets/bullet_rapid.tscn"),
}
@onready var trail_scene = preload("res://Entities/Scenes/FX/scent_trail.tscn")
@onready var weapons_container = $weapons_container
@onready var sprite = $Sprite2D
@onready var walk_sound_player = $Sounds/WalkSoundPlayer
@onready var cursor_script = $mouse_icon
@onready var audio_stream_dead_player: AudioStreamPlayer2D = $Sounds/AudioStreamDeadPlayer
@onready var damage_timer: Timer = $Timers/damage_timer
@export var damage_interval = 0.1  # Intervalo entre daños por contacto
@onready var double_damage_icon: Sprite2D = $DoubleIconAnchor/DoubleDamageIcon

var weapons = []
var current_weapon_index = 0

var weapon_damage = {
	"bazooka": 40,
	"m16": 15
}

func _ready() -> void:
	# Set up player and weapons when the scene starts
	weapons = weapons_container.get_children()
	setup_weapons()
	update_visible_weapon()
	check_level_and_set_weapon()
	damage_timer.wait_time = damage_interval
	damage_timer.one_shot = false
	setup_double_damage_icon()
	
func setup_double_damage_icon():
	if not double_damage_icon:
		return
		
	double_damage_icon.visible = false
	
func take_damage(damage: float):
	if not is_in_portal:
		player_data.health -= damage
		if not is_flashing:
			flash_damage()
		if player_data.health <= 0:
			dead()

func setup_weapons():
	# Assign bullet types to each weapon
	for i in range(weapons.size()):
		var weapon = weapons[i]
		if i == 0:
			weapon.set_meta("bullet_type", "bazooka")
		elif i == 1:
			weapon.set_meta("bullet_type", "m16")
			
func increase_health(amount: int) -> void:
	# Increase player's health, capped at 4
	player_data.health += amount
	if player_data.health > 4:
		player_data.health = 4

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
		
		# Añadir esta sección para manejar el temporizador de doble daño
		if double_damage_active:
			double_damage_timer -= delta
			if double_damage_timer <= 0:
				deactivate_double_damage()
			else:
				update_double_damage_icon()
		
func handle_weapon_switch():
	if Input.is_action_just_pressed("switch_weapon"):
		switch_weapon()
			
func activate_double_damage():
	double_damage_active = true
	double_damage_timer = DOUBLE_DAMAGE_DURATION
	if double_damage_icon:
		double_damage_icon.visible = true

func deactivate_double_damage():
	double_damage_active = false

	if double_damage_icon:
		double_damage_icon.visible = false
	
func update_double_damage_icon():
	if double_damage_icon:
		# Opcional: Hacer que el icono parpadee cuando quede poco tiempo
		var blink_threshold = 3.0  # Comenzar a parpadear cuando queden 3 segundos
		if double_damage_timer <= blink_threshold:
			double_damage_icon.visible = sin(double_damage_timer * 10) > 0
		else:
			double_damage_icon.visible = true

func enter_portal():
	is_in_portal = true

func exit_portal():
	is_in_portal = false

func bullet_type_shooting(delta: float):
	# Handle shooting based on the current weapon type
	var current_weapon = weapons[current_weapon_index]
	var bullet_type = current_weapon.get_meta("bullet_type", "bazooka")

	# Fast shooting (M16)
	if bullet_type == "m16" and Input.is_action_pressed("ui_shoot") and player_data.ammo > 0 and weapons_container.visible:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			player_data.ammo -= 1
			instance_bullet()
			shoot_timer = rapid_shoot_delay

	# Normal shooting (Bazooka)
	elif bullet_type != "m16" and Input.is_action_pressed("ui_shoot") and player_data.ammo > 0 and weapons_container.visible:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			player_data.ammo -= 1
			instance_bullet()
			shoot_timer = bazooka_shoot_delay

func check_level_and_set_weapon() -> void:
	# Show or hide weapons based on the level
	var current_scene = get_tree().current_scene
	var visible_levels = ["main_dungeon", "main_dungeon_2", "labyrinth_level"]
	
	if current_scene.name in visible_levels:
		weapons_container.visible = true
	else:
		weapons_container.visible = false
		update_animation_without_gun()

func movement(delta: float) -> void:
	# Handle player movement and animations
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
		# Play walking sound if the player is moving
		walk_sound_timer -= delta
		if walk_sound_timer <= 0:
			walk_sound_player.play()
			walk_sound_timer = walk_sound_interval
	else:
		walk_sound_timer = 0
	
	move_and_slide()

func target_mouse() -> void:
	# Aim weapons towards the mouse when using keyboard and mouse
	if not is_dead and weapons_container.visible:
		var mouse_movement = get_global_mouse_position()
		pos = global_position
		weapons_container.look_at(mouse_movement)
		rot = rad_to_deg((mouse_movement - pos).angle())

		update_weapon_flip()

func joystick_aiming(delta: float) -> void:
	# Aim using a joystick when using a gamepad
	if not is_dead and is_using_gamepad and weapons_container.visible:
		var direction: Vector2
		direction.x = Input.get_action_strength("rs_right") - Input.get_action_strength("rs_left")
		direction.y = Input.get_action_strength("rs_down") - Input.get_action_strength("rs_up")

		if direction.length() > gamepad_deadzone:
			weapons_container.rotation = direction.angle()
			rot = rad_to_deg(direction.angle())

			update_weapon_flip()

func detect_input_device() -> void:
	# Detect if the player is using a gamepad or mouse
	var gamepad_input = abs(Input.get_action_strength("rs_right")) + abs(Input.get_action_strength("rs_left")) + abs(Input.get_action_strength("rs_up")) + abs(Input.get_action_strength("rs_down"))
	var mouse_movement = Input.get_last_mouse_velocity()

	if gamepad_input > gamepad_deadzone:
		is_using_gamepad = true
		cursor_script.is_using_gamepad = true
		last_input_time = Time.get_ticks_msec()
	elif mouse_movement.length() > 0:
		is_using_gamepad = false
		cursor_script.is_using_gamepad = false

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func instance_bullet() -> void:
	# Spawn a bullet when shooting
	var current_weapon = weapons[current_weapon_index]
	var bullet_type = current_weapon.get_meta("bullet_type", "bazooka")
	
	var bullet_scene = bullet_scenes.get(bullet_type, bullet_scenes["bazooka"])
	
	var bullet = bullet_scene.instantiate()
	
	# Apply the doble damage
	var damage_multiplier = 2 if double_damage_active else 1
	bullet.damage = weapon_damage[bullet_type] * damage_multiplier
	
	var bullet_point = current_weapon.get_node("bullet_point")
	bullet.direction = (bullet_point.global_position - weapons_container.global_position).normalized()
	bullet.global_position = bullet_point.global_position
	get_tree().root.add_child(bullet)
	
	if bullet_type == "bazooka":
		$Sounds/AudioStreamBazookaShot.play()
	elif bullet_type == "m16":
		$Sounds/AudioStreamM16Shot.play()

func animation() -> void:
	# Handle player animations (idle, moving, or dead)
	if is_dead:
		if not $player_animation.is_playing() or $player_animation.current_animation != "Dead":
			$player_animation.play("Dead")
	elif input_movement != Vector2.ZERO:
		if not $player_animation.is_playing() or $player_animation.current_animation != "Move":
			$player_animation.play("Move")
	else:
		if not $player_animation.is_playing() or $player_animation.current_animation != "Idle":
			$player_animation.play("Idle")

func update_animation_without_gun() -> void:
	# Update animations when no weapons are visible
	if input_movement != Vector2.ZERO:
		if not $player_animation.is_playing() or $player_animation.current_animation != "Move":
			$player_animation.play("Move")
	else:
		if not $player_animation.is_playing() or $player_animation.current_animation != "Idle":
			$player_animation.play("Idle")
			
func switch_weapon():
	current_weapon_index = (current_weapon_index + 1) % weapons.size()
	update_visible_weapon()

func update_visible_weapon():
	for i in range(weapons.size()):
		weapons[i].visible = (i == current_weapon_index)

func update_weapon_flip():
	# Flip the weapon and sprite depending on the aim direction
	var current_weapon = weapons[current_weapon_index]
	var gun_sprite = current_weapon.get_node("gun_sprite")
	if rot >= -90 and rot <= 90:
		gun_sprite.flip_v = false
		sprite.flip_h = false
	else:
		gun_sprite.flip_v = true
		sprite.flip_h = true

func dead() -> void:
	# Handle player death and play death animation/sound
	if not is_dead:
		is_dead = true
		velocity = Vector2.ZERO
		weapons_container.visible = false
		audio_stream_dead_player.play()
		$player_animation.play("Dead")

		player_data.ammo += 10
		
		# Reset kill count and kill streak
		player_data.kill_count = 0
		player_data.reset_kill_streak()

func _on_anim_animation_finished(anim_name: StringName) -> void:
	# Reload the scene after death animation finishes
	if anim_name == "Dead":
		# Store the highest kill streak before resetting
		var highest_streak = player_data.highest_kill_streak
		
		# Reset all stats except highest_kill_streak
		player_data.reset_stats()
		
		# Restore the highest kill streak
		player_data.highest_kill_streak = highest_streak
		
		get_tree().reload_current_scene()
		#player_data.health = 4

func reset_state():
	# Reset player state to move
	current_state = player_states.MOVE

func instance_trail():
	# Spawn a trail effect
	var trail = trail_scene.instantiate()
	trail.global_position = global_position
	get_tree().root.add_child(trail)

func _on_trail_timer_timeout() -> void:
	# Spawn a trail periodically
	instance_trail()
	$Timers/trail_timer.start()

func flash_damage():
	if is_flashing:
		return
	
	is_flashing = true
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0.7)
	
	var flash_duration = 0.01
	var fade_duration = 0.1
	
	await get_tree().create_timer(flash_duration).timeout
	
	var tween = create_tween()
	tween.tween_property($Sprite2D.material, "shader_parameter/flash_modifier", 0.0, fade_duration)
	tween.tween_callback(func(): is_flashing = false)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") and not is_in_portal:
		enemies_in_contact += 1
		if enemies_in_contact == 1:
			damage_timer.start()

func _on_hitbox_area_exited(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		enemies_in_contact -= 1
		if enemies_in_contact == 0:
			damage_timer.stop()

func _on_damage_timer_timeout() -> void:
	if not is_in_portal and enemies_in_contact > 0:
		take_damage(contact_damage)
