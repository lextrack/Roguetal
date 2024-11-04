extends Node

enum PowerUpType {
	DAMAGE,
	SPEED,
	DEFENSE,
	BULLET_HELL,
	CRITICAL_CHANCE  # Nuevo power-up
}

const POWER_UP_BASE_MULTIPLIERS = {
	PowerUpType.DAMAGE: 1.1,
	PowerUpType.SPEED: 1.1,
	PowerUpType.DEFENSE: 1.1,
	PowerUpType.BULLET_HELL: 1.0,
	PowerUpType.CRITICAL_CHANCE: 1.15  # 15% de probabilidad base
}

func get_base_multiplier(type: PowerUpType) -> float:
	return POWER_UP_BASE_MULTIPLIERS[type]
