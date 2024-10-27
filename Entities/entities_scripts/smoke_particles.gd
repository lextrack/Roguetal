extends GPUParticles2D

func _ready():
	# Detectar si estamos en un nivel oscuro
	var is_dark_level = get_tree().current_scene.name == "labyrinth_level"
	
	emitting = true
	one_shot = false
	amount = 12
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
	
	# Ajustar color según el nivel
	if is_dark_level:
		# En niveles oscuros: humo más brillante y visible
		particles_material.color = Color(1.0, 1.0, 1.0, 0.5)
		var gradient = create_color_ramp(
			Color(1.0, 1.0, 1.0, 0.7),  # Más brillante
			Color(0.8, 0.8, 0.8, 0.0)   # Desvanecimiento suave
		)
		particles_material.color_ramp = gradient
	else:
		# En niveles iluminados: humo más oscuro y sutil
		particles_material.color = Color(0.6, 0.6, 0.6, 0.3)
		var gradient = create_color_ramp(
			Color(0.7, 0.7, 0.7, 0.5),  # Más oscuro
			Color(0.5, 0.5, 0.5, 0.0)   # Desvanecimiento más marcado
		)
		particles_material.color_ramp = gradient
	
	process_material = particles_material
	texture = preload("res://Sprites/smoke4.png")
	
func create_color_ramp(initial_color: Color, final_color: Color) -> Gradient:
	var gradient = Gradient.new()
	gradient.colors = [initial_color, final_color]
	gradient.offsets = [0.0, 1.0]
	return gradient
