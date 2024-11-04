extends Node

signal power_up_changed(type: int, multiplier: float)

var multipliers = {
	PowerUpTypes.PowerUpType.DAMAGE: 1.0,
	PowerUpTypes.PowerUpType.SPEED: 1.0,
	PowerUpTypes.PowerUpType.DEFENSE: 1.0,
	PowerUpTypes.PowerUpType.BULLET_HELL: 0.0,
	PowerUpTypes.PowerUpType.CRITICAL_CHANCE: 1.0  # Nuevo power-up
}

func reset_power_ups():
	for type in PowerUpTypes.PowerUpType.values():
		if type == PowerUpTypes.PowerUpType.BULLET_HELL:
			multipliers[type] = 0.0
		else:
			multipliers[type] = 1.0
	
	for type in PowerUpTypes.PowerUpType.values():
		call_deferred("emit_signal", "power_up_changed", type, multipliers[type])

func activate_power_up(type: PowerUpTypes.PowerUpType):
	if type == PowerUpTypes.PowerUpType.BULLET_HELL:
		multipliers[type] = PowerUpTypes.get_base_multiplier(type)
	else:
		multipliers[type] *= PowerUpTypes.get_base_multiplier(type)
	
	call_deferred("emit_signal", "power_up_changed", type, multipliers[type])

func get_multiplier(type: PowerUpTypes.PowerUpType):
	return multipliers[type]
