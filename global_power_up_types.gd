extends Node

enum PowerUpType {
	DAMAGE,
	SPEED
}

const POWER_UP_BASE_MULTIPLIERS = {
	PowerUpType.DAMAGE: 1.2,
	PowerUpType.SPEED: 1.1
}

func get_base_multiplier(type: PowerUpType) -> float:
	return POWER_UP_BASE_MULTIPLIERS[type]
