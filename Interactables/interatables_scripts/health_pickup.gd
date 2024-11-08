extends Area2D
@export var health_increase = 4
@onready var pickup_object: AudioStreamPlayer2D = $pickup_object

func _ready() -> void:
	$heart_collider.set_deferred("disabled", false)

func _on_area_entered(area: Area2D) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		pickup_object.play()
		create_heart_effect()
		await pickup_object.finished
		body.increase_health(health_increase)
		queue_free()

func create_heart_effect():
	var effect = CPUParticles2D.new()
	effect.emitting = true
	effect.one_shot = true
	effect.explosiveness = 0.8
	effect.amount = 24 
	effect.lifetime = 2.0
	effect.spread = 180
	effect.direction = Vector2(0, -1)
	effect.gravity = Vector2(0, -70) 
	effect.initial_velocity_min = 20
	effect.initial_velocity_max = 50
	effect.color = Color("#ff1744")
	effect.color_ramp = create_color_ramp()
	
	effect.scale_amount_min = 3.0
	effect.scale_amount_max = 5.0 
	effect.damping_min = 2.0
	effect.damping_max = 5.0
	effect.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	effect.emission_sphere_radius = 18.0
	
	add_child(effect)
	
	await get_tree().create_timer(effect.lifetime).timeout
	effect.queue_free()

func create_color_ramp() -> Gradient:
	var gradient = Gradient.new()
	gradient.colors = [
		Color("#ff1744"),
		Color("#ff174400")
	]
	gradient.offsets = [0.0, 1.0]
	return gradient
