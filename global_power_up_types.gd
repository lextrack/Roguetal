extends Node

enum PowerUpType {
	DAMAGE,
	SPEED,
	DEFENSE,
	BULLET_HELL,
	CRITICAL_CHANCE,
	ENEMY_SLOW,
	SHOTGUN_FIRE
}

var multipliers = {
	PowerUpType.DAMAGE: 1.0,
	PowerUpType.SPEED: 1.0,
	PowerUpType.DEFENSE: 1.0,
	PowerUpType.BULLET_HELL: 0.0,
	PowerUpType.CRITICAL_CHANCE: 1.0,
	PowerUpType.ENEMY_SLOW: 1.0,
	PowerUpType.SHOTGUN_FIRE: 0.0
}

const POWER_UP_BASE_MULTIPLIERS = {
	PowerUpType.DAMAGE: 1.1,
	PowerUpType.SPEED: 1.07,
	PowerUpType.DEFENSE: 1.1,
	PowerUpType.BULLET_HELL: 1.0,
	PowerUpType.CRITICAL_CHANCE: 1.05,
	PowerUpType.ENEMY_SLOW: 0.95,
	PowerUpType.SHOTGUN_FIRE: 1.0
}

func get_base_multiplier(type: PowerUpType) -> float:
	return POWER_UP_BASE_MULTIPLIERS[type]

func get_multiplier(type: PowerUpType) -> float:
	return multipliers[type]
