extends Area2D

static var last_impact_time = 0
const IMPACT_SOUND_COOLDOWN = 0.1

@onready var fx_scene = preload("res://Entities/Scenes/FX/fx_shotgun_bullet.tscn")
@onready var fire_particles = preload("res://Entities/Scenes/FX/fire_particles.tscn")

@export var base_speed = 250
@export var damage = 1
@export var spread_angle = 20
@export var speed_variation = 50
@export var start_delay_max = 0.05

var has_fire_effect: bool = false
var direction = Vector2.RIGHT
var speed: float
var start_delay: float

func _ready() -> void:
	apply_spread()
	rotation = direction.angle()
	speed = base_speed + randf_range(-speed_variation, speed_variation)
	start_delay = randf_range(0, start_delay_max)
	
	if has_fire_effect:
		setup_fire_effects()
	
	if start_delay > 0:
		set_physics_process(false)
		await get_tree().create_timer(start_delay).timeout
		set_physics_process(true)

func setup_fire_effects():
	modulate = Color(1.5, 0.7, 0.4)
	var particles = fire_particles.instantiate()
	add_child(particles)
	particles.emitting = true

func impact(body: Node2D):
	Globals.camera.screen_shake(1.0, 0.1, 0.05)
	
	$CollisionShape2D.call_deferred("set_disabled", true)
	set_physics_process(false)
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_impact_time > IMPACT_SOUND_COOLDOWN:
		play_impact_sound()
		last_impact_time = current_time
	
	instance_fx()
	
	if body.is_in_group("enemy"):
		body.take_damage(damage, self)
		if has_fire_effect:
			body.apply_fire_effect()
	
	queue_free()

func _process(delta: float) -> void:
	translate(direction * speed * delta)

func apply_spread():
	var random_angle = randf_range(-spread_angle, spread_angle)
	direction = direction.rotated(deg_to_rad(random_angle))
	
	var additional_spread = randf_range(-5, 5)
	direction = direction.rotated(deg_to_rad(additional_spread))

func _on_body_entered(body: Node2D) -> void:
	impact(body)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		impact(area)

func play_impact_sound():
	var impact_node = Node2D.new()
	impact_node.global_position = global_position
	var impact_sound = AudioStreamPlayer.new()
	impact_sound.stream = $AudioStreamImpactShotgun.stream
	impact_node.add_child(impact_sound)
	get_tree().root.add_child(impact_node)
	impact_sound.play()
	
	await get_tree().create_timer(impact_sound.stream.get_length()).timeout
	impact_node.queue_free()

func _on_visible_screen_exited() -> void:
	queue_free()

func instance_fx():
	var fx = fx_scene.instantiate()
	fx.global_position = global_position
	fx.scale = Vector2(0.5, 0.5)
	get_tree().root.add_child(fx)
