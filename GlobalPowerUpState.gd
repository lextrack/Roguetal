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

# Definimos los límites máximos para cada tipo de power-up
const MAX_MULTIPLIERS = {
	PowerUpTypes.PowerUpType.DAMAGE: 3.0,        # 300% daño máximo
	PowerUpTypes.PowerUpType.SPEED: 2.0,         # 200% velocidad máxima
	PowerUpTypes.PowerUpType.DEFENSE: 3.0,       # 300% defensa máxima
	PowerUpTypes.PowerUpType.BULLET_HELL: 1.0,   # Activado/Desactivado
	PowerUpTypes.PowerUpType.CRITICAL_CHANCE: 2.0, # 200% prob. crítico máximo
	PowerUpTypes.PowerUpType.ENEMY_SLOW: 0.3,    # 30% velocidad enemiga mínima
	PowerUpTypes.PowerUpType.SHOTGUN_FIRE: 1.0   # Activado/Desactivado
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
	var new_value: float
	
	if type == PowerUpTypes.PowerUpType.BULLET_HELL or type == PowerUpTypes.PowerUpType.SHOTGUN_FIRE:
		new_value = PowerUpTypes.get_base_multiplier(type)
	elif type == PowerUpTypes.PowerUpType.ENEMY_SLOW:
		new_value = multipliers[type] * PowerUpTypes.get_base_multiplier(type)
		new_value = clamp(new_value, MAX_MULTIPLIERS[type], 1.0) 
	else:
		new_value = multipliers[type] * PowerUpTypes.get_base_multiplier(type)
		new_value = min(new_value, MAX_MULTIPLIERS[type])
	
	multipliers[type] = new_value
	call_deferred("emit_signal", "power_up_changed", type, multipliers[type])

func get_multiplier(type: PowerUpTypes.PowerUpType) -> float:
	return multipliers[type]
