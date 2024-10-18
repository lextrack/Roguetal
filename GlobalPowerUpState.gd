extends Node

var multipliers = {
	PowerUpTypes.PowerUpType.DAMAGE: 1.0,
	PowerUpTypes.PowerUpType.SPEED: 1.0,
	PowerUpTypes.PowerUpType.DEFENSE: 1.0,
	PowerUpTypes.PowerUpType.BULLET_HELL: 0.0
}

func reset_power_ups():
	for type in PowerUpTypes.PowerUpType.values():
		multipliers[type] = 1.0
	
	multipliers[PowerUpTypes.PowerUpType.BULLET_HELL] = 0.0
	
	for type in PowerUpTypes.PowerUpType.values():
		emit_signal("power_up_changed", type, multipliers[type])

func activate_power_up(type: PowerUpTypes.PowerUpType):
	multipliers[type] = PowerUpTypes.get_base_multiplier(type)
	emit_signal("power_up_changed", type, multipliers[type])

func get_multiplier(type: PowerUpTypes.PowerUpType):
	return multipliers[type]
