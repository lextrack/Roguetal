extends Node

enum PowerUpType {
	DAMAGE,
	SPEED,
	DEFENSE,
	BULLET_HELL
}

const POWER_UP_BASE_MULTIPLIERS = {
	PowerUpType.DAMAGE: 1.2,
	PowerUpType.SPEED: 1.1,
	PowerUpType.DEFENSE: 1.2,
	PowerUpType.BULLET_HELL: 1.0
}

func get_base_multiplier(type: PowerUpType) -> float:
	return POWER_UP_BASE_MULTIPLIERS[type]
