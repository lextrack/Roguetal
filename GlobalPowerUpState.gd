extends Node

var multipliers = {
	PowerUpTypes.PowerUpType.DAMAGE: 1.0,
	PowerUpTypes.PowerUpType.SPEED: 1.0
}

func reset_power_ups():
	for type in PowerUpTypes.PowerUpType.values():
		multipliers[type] = 1.0

func activate_power_up(type: PowerUpTypes.PowerUpType):
	multipliers[type] *= PowerUpTypes.get_base_multiplier(type)

func get_multiplier(type: PowerUpTypes.PowerUpType):
	return multipliers[type]
