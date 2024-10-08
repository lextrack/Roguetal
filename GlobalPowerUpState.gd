extends Node

var damage_multiplier = 1.0
var speed_multiplier = 1.0

const BASE_DAMAGE_MULTIPLIER = 1.2
const BASE_SPEED_MULTIPLIER = 1.2

func reset_power_ups():
	damage_multiplier = 1.0
	speed_multiplier = 1.0

func activate_double_damage():
	damage_multiplier *= BASE_DAMAGE_MULTIPLIER

func activate_double_speed():
	speed_multiplier *= BASE_SPEED_MULTIPLIER

func get_damage_multiplier():
	return damage_multiplier

func get_speed_multiplier():
	return speed_multiplier
