extends CharacterBody2D

@onready var fx_scene = preload("res://Entities/Scenes/FX/fx_scene.tscn")
@onready var ammo_scene = preload("res://Interactables/Scenes/ammo_1.tscn")
@export var speed = 30
@export var stuck_time_limit = 0.5

enum enemy_direction {RIGHT, LEFT, UP, DOWN, CHASE}
var new_direction = enemy_direction.RIGHT
var change_direction
var stuck_timer = 0.0
var is_stuck = false
var current_health
@export var max_health = 5
@onready var hit_damage: AudioStreamPlayer2D = $hit_damage

@onready var target = get_node("../Player")

func _ready() -> void:
	chosee_direction()
	$timer_direction.start()
	current_health = max_health

func _process(delta: float) -> void:
	if is_stuck:
		stuck_timer += delta
		if stuck_timer >= stuck_time_limit:
			chosee_direction()
			stuck_timer = 0.0
			is_stuck = false
	
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

func move_in_direction(direction: Vector2, animation: String) -> void:
	velocity = direction * speed
	$anim.play(animation)
	move_and_slide()
	
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
		take_damage(area.damage)

func take_damage(damage: int):
	current_health -= damage
	if current_health <= 0:
		die()
	else:
		hit_damage.play()
		flash_damage()

func die():
	instance_fx()
	instance_ammo()
	queue_free()
	
func flash_damage():
	$Sprite2D.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.modulate = Color(1, 1, 1)

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
	var chase_speed = 85
	var direction_vector = target.global_position - global_position
	var direction_to_target = direction_vector.normalized()
	velocity = direction_to_target * chase_speed
	animation()
	move_and_slide()
	
func animation():
	if velocity.x > 0:
		$anim.play("move_right")
	elif velocity.x < 0:
		$anim.play("move_left")
	elif velocity.y > 0:
		$anim.play("move_down")
	elif velocity.y < 0:
		$anim.play("move_up")

func _on_chase_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("follow"):
		new_direction = enemy_direction.CHASE
