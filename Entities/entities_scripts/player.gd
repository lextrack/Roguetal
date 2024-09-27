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

@export var speed: int
@export var walk_sound_interval = 0.4
@export var rapid_shoot_delay: float = 0.15

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

var weapons = []
var current_weapon_index = 0

var weapon_damage = {
	"bazooka": 3,
	"m16": 2
}

func _ready() -> void:
	weapons = weapons_container.get_children()
	setup_weapons()
	update_visible_weapon()
	check_level_and_set_weapon()

func setup_weapons():
	for i in range(weapons.size()):
		var weapon = weapons[i]
		if i == 0:
			weapon.set_meta("bullet_type", "bazooka")
		elif i == 1:
			weapon.set_meta("bullet_type", "m16")
			
func increase_health(amount: int) -> void:
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

		var current_weapon = weapons[current_weapon_index]
		var bullet_type = current_weapon.get_meta("bullet_type", "bazooka")

		#Fast shooting
		if bullet_type == "m16" and Input.is_action_pressed("ui_shoot") and player_data.ammo > 0 and weapons_container.visible:
			shoot_timer -= delta
			if shoot_timer <= 0.0:
				player_data.ammo -= 1
				instance_bullet()
				shoot_timer = rapid_shoot_delay
		# Normal shooting (bazooka)
		elif bullet_type != "m16" and Input.is_action_just_pressed("ui_shoot") and player_data.ammo > 0 and weapons_container.visible:
			player_data.ammo -= 1
			instance_bullet()

		if Input.is_action_just_pressed("switch_weapon"):
			switch_weapon()

func check_level_and_set_weapon() -> void:
	var current_scene = get_tree().current_scene
	var visible_levels = ["main_dungeon", "main_dungeon_2"]
	
	if current_scene.name in visible_levels:
		weapons_container.visible = true
	else:
		weapons_container.visible = false
		update_animation_without_gun()


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
	
	if Input.is_action_just_pressed("ui_shoot") and player_data.ammo > 0 and weapons_container.visible:
		player_data.ammo -= 1
		instance_bullet()

	if input_movement != Vector2.ZERO:
		walk_sound_timer -= delta
		if walk_sound_timer <= 0:
			walk_sound_player.play()
			walk_sound_timer = walk_sound_interval
	else:
		walk_sound_timer = 0
	
	move_and_slide()

func target_mouse() -> void:
	if is_dead == false and weapons_container.visible:
		var mouse_movement = get_global_mouse_position()
		pos = global_position
		weapons_container.look_at(mouse_movement)
		rot = rad_to_deg((mouse_movement - pos).angle())

		update_weapon_flip()

func joystick_aiming(delta: float) -> void:
	if is_dead == false and is_using_gamepad and weapons_container.visible:
		var direction: Vector2
		direction.x = Input.get_action_strength("rs_right") - Input.get_action_strength("rs_left")
		direction.y = Input.get_action_strength("rs_down") - Input.get_action_strength("rs_up")

		if direction.length() > gamepad_deadzone:
			weapons_container.rotation = direction.angle()
			rot = rad_to_deg(direction.angle())

			update_weapon_flip()

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

func instance_bullet() -> void:
	var current_weapon = weapons[current_weapon_index]
	var bullet_type = current_weapon.get_meta("bullet_type", "bazooka")
	
	var bullet_scene = bullet_scenes.get(bullet_type, bullet_scenes["bazooka"])
	
	var bullet = bullet_scene.instantiate()
	bullet.damage = weapon_damage[bullet_type]
	var bullet_point = current_weapon.get_node("bullet_point")
	bullet.direction = (bullet_point.global_position - weapons_container.global_position).normalized()
	bullet.global_position = bullet_point.global_position
	get_tree().root.add_child(bullet)
	
	if bullet_type == "bazooka":
		$Sounds/AudioStreamBazookaShot.play()
	elif bullet_type == "m16":
		$Sounds/AudioStreamM16Shot.play()

func animation() -> void:
	if is_dead:
		if not $anim.is_playing() or $anim.current_animation != "Dead":
			$anim.play("Dead")
	elif input_movement != Vector2.ZERO:
		if not $anim.is_playing() or $anim.current_animation != "Move":
			$anim.play("Move")
	else:
		if not $anim.is_playing() or $anim.current_animation != "Idle":
			$anim.play("Idle")

func update_animation_without_gun() -> void:
	if input_movement != Vector2.ZERO:
		if not $anim.is_playing() or $anim.current_animation != "Move":
			$anim.play("Move")
	else:
		if not $anim.is_playing() or $anim.current_animation != "Idle":
			$anim.play("Idle")

func dead() -> void:
	if not is_dead:
		is_dead = true
		velocity = Vector2.ZERO
		weapons_container.visible = false
		audio_stream_dead_player.play()
		$anim.play("Dead")

func reset_state():
	current_state = player_states.MOVE

func instance_trail():
	var trail = trail_scene.instantiate()
	trail.global_position = global_position
	get_tree().root.add_child(trail)

func _on_trail_timer_timeout() -> void:
	instance_trail()
	$trail_timer.start()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		flash_damage()
		player_data.health -= 1

func flash_damage():
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0.7)
	await get_tree().create_timer(0.3).timeout
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0)

func _on_anim_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Dead":
		get_tree().reload_current_scene()
		player_data.health = 4

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
