extends CharacterBody2D

enum player_states {MOVE, DEAD}

const MAGNET_RADIUS = 100.0

@export var contact_damage = 0.1
@export var speed: int
@export var base_speed: int
@export var walk_sound_interval = 0.4
@export var rapid_shoot_delay: float = 0.1
@export var bazooka_shoot_delay: float = 0.6
@export var damage_interval = 0.2

@onready var bullet_scenes = {
	"bazooka": preload("res://Entities/Scenes/Bullets/bullet_1.tscn"),
	"m16": preload("res://Entities/Scenes/Bullets/bullet_rapid.tscn"),
	"shotgun": preload("res://Entities/Scenes/Bullets/bullet_shotgun.tscn"),
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
@onready var double_damage_icon: Sprite2D = $hud_powerup/double_damage_icon
@onready var double_speed_icon: Sprite2D = $hud_powerup/double_speed_icon
@onready var double_defense_icon: Sprite2D = $hud_powerup/double_defense_icon
@onready var power_up_manager = $PowerUpManager
@onready var point_light: PointLight2D = $PointLight2D
@onready var light_powerup: PointLight2D = $hud_powerup/light_powerup


var light_disabled_by_timer = false
var current_state = player_states.MOVE
var is_dead = false
var is_using_gamepad = false
var last_input_time = 0.0
var gamepad_deadzone = 0.0
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
	weapons = weapons_container.get_children()
	setup_weapons()
	update_visible_weapon()
	check_level_and_set_weapon()
	
	damage_timer.wait_time = damage_interval
	damage_timer.one_shot = false
	setup_double_damage_icon()
	
	setup_double_speed_icon()
	base_speed = speed
	
	setup_magnet_area()
	add_to_group("player")
	
	power_up_manager_check()
	update_light_state()
	
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
		
func update_light_state() -> void:
	if point_light:
		var current_scene = get_tree().current_scene
		if current_scene.name == "labyrinth_level" and not light_disabled_by_timer:
			point_light.enabled = true
			light_powerup.enabled = true
		else:
			point_light.enabled = false
			light_powerup.enabled = false
	
func disable_light() -> void:
	if point_light and get_tree().current_scene.name == "labyrinth_level":
		point_light.enabled = false
		light_powerup.enabled = false
		light_disabled_by_timer = true

func enable_light() -> void:
	if point_light:
		point_light.enabled = true
		
	if light_powerup:
		light_powerup.enabled = true
	
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

func update_double_defense_icon(multiplier: float):
	if double_defense_icon:
		double_defense_icon.visible = multiplier > 1.0

func _on_damage_multiplier_changed(multiplier: float) -> void:
	update_double_damage_icon(multiplier)

func _on_speed_multiplier_changed(multiplier: float) -> void:
	speed = base_speed * multiplier
	update_double_speed_icon(multiplier)
	
func update_double_damage_icon(multiplier: float):
	if double_damage_icon:
		double_damage_icon.visible = multiplier > 1.0

func update_double_speed_icon(multiplier: float):
	if double_speed_icon:
		double_speed_icon.visible = multiplier > 1.0
		
func setup_double_defense_icon():
	if double_defense_icon:
		double_defense_icon.visible = false
		
func setup_double_damage_icon():
	if double_damage_icon:
		double_damage_icon.visible = false

func setup_double_speed_icon():
	if double_speed_icon:
		double_speed_icon.visible = false
	
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

func detect_input_device() -> void:
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

func target_mouse() -> void:
	if not is_dead and weapons_container.visible:
		var mouse_movement = get_global_mouse_position()
		weapons_container.look_at(mouse_movement)
		rot = rad_to_deg((mouse_movement - global_position).angle())
		update_weapon_flip()

func joystick_aiming(delta: float) -> void:
	if not is_dead and is_using_gamepad and weapons_container.visible:
		var direction: Vector2
		direction.x = Input.get_action_strength("rs_right") - Input.get_action_strength("rs_left")
		direction.y = Input.get_action_strength("rs_down") - Input.get_action_strength("rs_up")

		if direction.length() > gamepad_deadzone:
			weapons_container.rotation = direction.angle()
			rot = rad_to_deg(direction.angle())
			update_weapon_flip()
			
func instance_bullet() -> void:
	var current_weapon = weapons[current_weapon_index]
	var bullet_type = current_weapon.get_meta("bullet_type", "bazooka")
	
	var bullet_scene = bullet_scenes.get(bullet_type, bullet_scenes["bazooka"])
	
	var damage_multiplier = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.DAMAGE)
	
	var bullet_point = current_weapon.get_node("bullet_point")
	var base_direction = (bullet_point.global_position - weapons_container.global_position).normalized()
	
	if bullet_type == "shotgun":
		var num_pellets = 5
		for i in range(num_pellets):
			var bullet = bullet_scene.instantiate()
			bullet.damage = weapon_damage[bullet_type] * damage_multiplier
			bullet.direction = base_direction
			bullet.global_position = bullet_point.global_position
			bullet.base_speed = 250
			bullet.speed_variation = 50
			bullet.start_delay_max = 0.05
			get_tree().root.add_child(bullet)
		$Sounds/AudioStreamShotgunShot.play()
	else:
		var bullet = bullet_scene.instantiate()
		bullet.damage = weapon_damage[bullet_type] * damage_multiplier
		bullet.direction = base_direction
		bullet.global_position = bullet_point.global_position
		get_tree().root.add_child(bullet)
		
		if bullet_type == "bazooka":
			$Sounds/AudioStreamBazookaShot.play()
		elif bullet_type == "m16":
			$Sounds/AudioStreamM16Shot.play()

func bullet_type_shooting(delta: float):
	var current_weapon = weapons[current_weapon_index]
	var bullet_type = current_weapon.get_meta("bullet_type", "bazooka")

	if Input.is_action_pressed("ui_shoot") and player_data.ammo > 0 and weapons_container.visible:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			player_data.ammo -= 1
			instance_bullet()
			if bullet_type == "m16":
				shoot_timer = rapid_shoot_delay
			elif bullet_type == "shotgun":
				shoot_timer = 1.0
			else:
				shoot_timer = bazooka_shoot_delay

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
	current_weapon_index = (current_weapon_index + 1) % weapons.size()
	update_visible_weapon()

func update_visible_weapon():
	for i in range(weapons.size()):
		weapons[i].visible = (i == current_weapon_index)

func update_weapon_flip():
	var current_weapon = weapons[current_weapon_index]
	var gun_sprite = current_weapon.get_node("gun_sprite")
	if rot >= -90 and rot <= 90:
		gun_sprite.flip_v = false
		sprite.flip_h = false
	else:
		gun_sprite.flip_v = true
		sprite.flip_h = true

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

func take_damage(damage: float):
	if not is_in_portal:
		var defense_multiplier = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.DEFENSE)
		var actual_damage = damage / defense_multiplier
		player_data.health -= actual_damage
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

func dead() -> void:
	if not is_dead:
		is_dead = true
		
		stop_all_attractions()
		
		if magnet_area:
			magnet_area.monitoring = false
			magnet_area.monitorable = false
		
		velocity = Vector2.ZERO
		weapons_container.visible = false
		audio_stream_dead_player.play()
		$player_animation.play("Dead")

		player_data.ammo += 20
		player_data.kill_count = 0
		player_data.reset_kill_streak()
		
		if power_up_manager:
			power_up_manager.reset_power_ups()

func stop_all_attractions():
	var ammo_items = get_tree().get_nodes_in_group("ammo")
	for item in ammo_items:
		if item.has_method("stop_attraction"):
			item.stop_attraction()

func reset_state():
	current_state = player_states.MOVE

func instance_trail():
	var trail = trail_scene.instantiate()
	trail.global_position = global_position
	get_tree().root.add_child(trail)
	
func flash_damage():
	if is_flashing:
		return
	
	is_flashing = true
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0.7)
	
	var flash_duration = 0.1
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
		
func enter_portal(portal_type: String = ""):
	is_in_portal = true
	
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

func exit_portal():
	is_in_portal = false

func _on_hitbox_area_exited(area: Area2D) -> void:
	pass
