extends CharacterBody2D

enum enemy_direction {RIGHT, LEFT, UP, DOWN, CHASE, ATTACK}
var new_direction = enemy_direction.RIGHT
var change_direction
var stuck_timer = 0.0
var is_stuck = false
var current_health
var is_dead = false
var attack_cooldown = 0.0
var attack_range = 20.0
var last_movement_direction = Vector2.RIGHT

@onready var fx_scene = preload("res://Entities/Scenes/FX/fx_scene.tscn")
@onready var ammo_scene = preload("res://Interactables/Scenes/ammo_1.tscn")
@export var speed = 30
@export var stuck_time_limit = 0.5
@export var max_health = 60
@export var attack_damage = 10
@export var attack_cooldown_time = 1.0

@onready var target = get_node("../Player")
@onready var hit_damage_sound: AudioStreamPlayer2D = $hit_damage_sound
@onready var die_enemy_sound: AudioStreamPlayer2D = $die_enemy_sound
@onready var die_sprite: Sprite2D = $Sprites/die_sprite
@onready var attack_sprite: Sprite2D = $Sprites/attack_sprite
@onready var die_animation_enemy: AnimationPlayer = $Animations/die_animation_enemy
@onready var attack_animation_enemy: AnimationPlayer = $Animations/attack_animation_enemy

func _ready() -> void:
	chosee_direction()
	$timer_direction.start()
	current_health = max_health
	
	if die_sprite != null:
		die_sprite.hide()
	else:
		print("Error: die_sprite no encontrado")
	
	if attack_sprite != null:
		attack_sprite.hide()
	else:
		print("Error: attack_sprite no encontrado")

func _process(delta: float) -> void:
	if is_dead:
		return

	if is_stuck:
		stuck_timer += delta
		if stuck_timer >= stuck_time_limit:
			chosee_direction()
			stuck_timer = 0.0
			is_stuck = false
	
	attack_cooldown -= delta
	
	match new_direction:
		enemy_direction.RIGHT:
			move_in_direction(Vector2.RIGHT, "move_right")
		enemy_direction.LEFT:
			move_in_direction(Vector2.LEFT, "move_left")
		enemy_direction.UP:
			move_in_direction(Vector2.UP, "move_up")
		enemy_direction.DOWN:
			move_in_direction(Vector2.DOWN, "move_down")
		enemy_direction.CHASE:
			chase_state()
		enemy_direction.ATTACK:
			attack_state()

func move_in_direction(direction: Vector2, animation: String) -> void:
	if is_dead:
		return

	velocity = direction * speed
	$Animations/move_animation_enemy.play(animation)
	move_and_slide()
	
	last_movement_direction = direction
	
	if is_on_wall() or is_on_ceiling() or is_on_floor():
		is_stuck = true

func chosee_direction():
	change_direction = randi() % 4
	random_direction()

func random_direction():
	match change_direction:
		0:
			new_direction = enemy_direction.RIGHT
		1:
			new_direction = enemy_direction.LEFT
		2:
			new_direction = enemy_direction.UP
		3:
			new_direction = enemy_direction.DOWN

func _on_timer_timeout() -> void:
	chosee_direction()
	$timer_direction.start()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		take_damage(area.damage, area)

func take_damage(damage: int, bullet: Area2D):
	if is_dead:
		return

	current_health -= damage
	if current_health <= 0:
		die()
	else:
		hit_damage_sound.play()
		flash_damage()
		show_damage(damage)
	
	bullet.queue_free()

func show_damage(damage: int) -> void:
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
	
	$Sprites/normal_movement_enemy.hide()

	die_sprite.show()
	die_animation_enemy.play("dead")
	
	await die_animation_enemy.animation_finished
	queue_free()

func flash_damage():
	$Sprites/normal_movement_enemy.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	$Sprites/normal_movement_enemy.modulate = Color(1, 1, 1)

func instance_fx():
	var fx = fx_scene.instantiate()
	fx.global_position = global_position
	get_tree().root.call_deferred("add_child", fx)

func instance_ammo():
	var drop_chance = randf()
	if drop_chance < 0.5:
		var ammo = ammo_scene.instantiate()
		ammo.global_position = global_position
		get_tree().root.call_deferred("add_child", ammo)

func chase_state():
	var chase_speed = 80
	var direction_vector = target.global_position - global_position
	var distance_to_target = direction_vector.length()
	
	if distance_to_target <= attack_range and attack_cooldown <= 0:
		new_direction = enemy_direction.ATTACK
		return
	
	var direction_to_target = direction_vector.normalized()
	velocity = direction_to_target * chase_speed
	animation()
	move_and_slide()
	
func animation():
	if velocity.x > 0:
		$Animations/move_animation_enemy.play("move_right")
	elif velocity.x < 0:
		$Animations/move_animation_enemy.play("move_left")
	elif velocity.y > 0:
		$Animations/move_animation_enemy.play("move_down")
	elif velocity.y < 0:
		$Animations/move_animation_enemy.play("move_up")

func attack_state():
	velocity = Vector2.ZERO
	$Sprites/normal_movement_enemy.hide()
	attack_sprite.show()
	
	var attack_animation = "attack_right"
	if last_movement_direction.x > 0:
		attack_animation = "attack_right"
	elif last_movement_direction.x < 0:
		attack_animation = "attack_left"
	elif last_movement_direction.y > 0:
		attack_animation = "attack_down"
	elif last_movement_direction.y < 0:
		attack_animation = "attack_up"
	
	attack_animation_enemy.play(attack_animation)
	
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	
	attack_cooldown = attack_cooldown_time
	await attack_animation_enemy.animation_finished
	
	$Sprites/normal_movement_enemy.show()
	attack_sprite.hide()
	new_direction = enemy_direction.CHASE

func _on_chase_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("follow"):
		new_direction = enemy_direction.CHASE
