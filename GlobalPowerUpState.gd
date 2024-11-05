extends Node
signal power_up_changed(type: int, multiplier: float)
var multipliers = {
	PowerUpTypes.PowerUpType.DAMAGE: 1.0,
	PowerUpTypes.PowerUpType.SPEED: 1.0,
	PowerUpTypes.PowerUpType.DEFENSE: 1.0,
	PowerUpTypes.PowerUpType.BULLET_HELL: 0.0,
	PowerUpTypes.PowerUpType.CRITICAL_CHANCE: 1.0,
	PowerUpTypes.PowerUpType.ENEMY_SLOW: 1.0,
	PowerUpTypes.PowerUpType.SHOTGUN_FIRE: 0.0
}

func reset_power_ups():
	for type in PowerUpTypes.PowerUpType.values():
		if type == PowerUpTypes.PowerUpType.BULLET_HELL or type == PowerUpTypes.PowerUpType.SHOTGUN_FIRE:
			multipliers[type] = 0.0
		else:
			multipliers[type] = 1.0
	
	for type in PowerUpTypes.PowerUpType.values():
		call_deferred("emit_signal", "power_up_changed", type, multipliers[type])

func activate_power_up(type: PowerUpTypes.PowerUpType):
	if type == PowerUpTypes.PowerUpType.BULLET_HELL or type == PowerUpTypes.PowerUpType.SHOTGUN_FIRE:
		multipliers[type] = PowerUpTypes.get_base_multiplier(type)
	elif type == PowerUpTypes.PowerUpType.ENEMY_SLOW:
		multipliers[type] *= PowerUpTypes.get_base_multiplier(type)
		multipliers[type] = max(multipliers[type], 0.3)
	else:
		multipliers[type] *= PowerUpTypes.get_base_multiplier(type)
	
	call_deferred("emit_signal", "power_up_changed", type, multipliers[type])
	
func get_multiplier(type: PowerUpTypes.PowerUpType) -> float:
	return multipliers[type]
