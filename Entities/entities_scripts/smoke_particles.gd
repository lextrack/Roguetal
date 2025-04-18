extends GPUParticles2D

func _ready():
	var is_dark_level = get_tree().current_scene.name == "labyrinth_level"
	
	emitting = true
	one_shot = false
	amount = 5
	lifetime = 0.8
	
	var particles_material = ParticleProcessMaterial.new()
	particles_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	particles_material.direction = Vector3(0, -1, 0)
	particles_material.spread = 25.0
	particles_material.gravity = Vector3(0, -25, 0)
	particles_material.initial_velocity_min = 25.0
	particles_material.initial_velocity_max = 45.0
	particles_material.scale_min = 0.4
	particles_material.scale_max = 0.8
	
	if is_dark_level:
		particles_material.color = Color(1.0, 1.0, 1.0, 0.5)
		var gradient = create_color_ramp(
			Color(1.0, 1.0, 1.0, 0.7),
			Color(0.8, 0.8, 0.8, 0.0)
		)
		particles_material.color_ramp = gradient
	else:
		particles_material.color = Color(0.9, 0.9, 0.9, 0.5)
		var gradient = create_color_ramp(
			Color(0.9, 0.9, 0.9, 0.6),
			Color(0.7, 0.7, 0.7, 0.0)
		)
		particles_material.color_ramp = gradient
	
	process_material = particles_material
	texture = preload("res://Sprites/smoke4.png")
	
func create_color_ramp(initial_color: Color, final_color: Color) -> Gradient:
	var gradient = Gradient.new()
	gradient.colors = [initial_color, final_color]
	gradient.offsets = [0.0, 1.0]
	return gradient
