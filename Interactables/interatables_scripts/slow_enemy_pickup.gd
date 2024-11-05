extends Area2D

@onready var pickup_object: AudioStreamPlayer2D = $pickup_object

func _on_body_entered(body):
	if body.name == "Player" and body.has_node("PowerUpManager"):
		pickup_object.play()
		create_pickup_effect()
		await pickup_object.finished
		var power_up_manager = body.get_node("PowerUpManager")
		power_up_manager.activate_power_up(PowerUpTypes.PowerUpType.ENEMY_SLOW)
		var new_multiplier = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.ENEMY_SLOW)
		queue_free()

func create_pickup_effect():
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
	effect.color = Color(0, 1, 0)
	add_child(effect)
	
	await get_tree().create_timer(effect.lifetime).timeout
	effect.queue_free()
