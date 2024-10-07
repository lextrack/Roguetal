extends Area2D

@onready var pickup_object: AudioStreamPlayer2D = $pickup_object

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_body_entered(body):
	if body.name == "Player" and body.has_node("PowerUpManager"):
		pickup_object.play()
		create_pickup_effect()
		await pickup_object.finished
		var power_up_manager = body.get_node("PowerUpManager")
		power_up_manager.activate_double_damage()
		var new_multiplier = power_up_manager.get_damage_multiplier()
		show_damage_increase(new_multiplier)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	pass

func create_pickup_effect():
	# Crear un efecto de partículas o un sprite animado
	# para mostrar visualmente que el power-up se ha recogido
	var effect = CPUParticles2D.new()
	effect.emitting = true
	effect.one_shot = true
	effect.explosiveness = 0.8
	effect.amount = 20
	effect.lifetime = 0.5
	effect.direction = Vector2(0, -1)
	effect.gravity = Vector2(0, 98)
	effect.initial_velocity_min = 50
	effect.initial_velocity_max = 100
	effect.color = Color(1, 0, 0)  # Color rojo para daño
	add_child(effect)
	
	# Eliminar el efecto después de que termine
	await get_tree().create_timer(effect.lifetime).timeout
	effect.queue_free()

func show_damage_increase(multiplier: float):
	# Mostrar un mensaje flotante con el nuevo multiplicador de daño
	var label = Label.new()
	label.text = "Damage x%.1f!" % multiplier
	label.add_theme_color_override("font_color", Color(1, 0, 0))  # Color rojo para daño
	add_child(label)
	
	# Animación simple para el mensaje
	var tween = create_tween()
	tween.tween_property(label, "position", Vector2(0, -50), 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	
	# Eliminar el label después de la animación
	await tween.finished
	label.queue_free()
