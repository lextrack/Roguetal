extends Area2D

@onready var pickup_object: AudioStreamPlayer2D = $pickup_object

func _on_body_entered(body):
	if body.name == "Player" and body.has_node("PowerUpManager"):
		var power_up_manager = body.get_node("PowerUpManager")
		var current_multiplier = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.SHOTGUN_FIRE)
		var new_multiplier = power_up_manager.get_multiplier(PowerUpTypes.PowerUpType.SHOTGUN_FIRE)
		pickup_object.play()
		create_pickup_effect()
		
		power_up_manager.activate_power_up(PowerUpTypes.PowerUpType.SHOTGUN_FIRE)
		
		await pickup_object.finished
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
	effect.color = Color(1, 0, 0)
	add_child(effect)
	
	await get_tree().create_timer(effect.lifetime).timeout
	effect.queue_free()
