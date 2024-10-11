# File: power_up_manager.gd
extends Node

signal power_up_changed(type: int, multiplier: float)

const DUNGEON_LEVELS = ["main_dungeon", "main_dungeon_2", "labyrinth_level"]

func _ready():
	update_power_up_states()

func update_power_up_states() -> void:
	for type in PowerUpTypes.PowerUpType.values():
		emit_signal("power_up_changed", type, GlobalPowerUpState.get_multiplier(type))

func activate_power_up(type: int) -> void:
	GlobalPowerUpState.activate_power_up(type)
	emit_signal("power_up_changed", type, GlobalPowerUpState.get_multiplier(type))

func reset_power_ups() -> void:
	GlobalPowerUpState.reset_power_ups()
	update_power_up_states()

func get_multiplier(type: int) -> float:
	return GlobalPowerUpState.get_multiplier(type)

func handle_level_transition(new_level: String) -> void:
	if new_level == "main_world":
		reset_power_ups()
	elif new_level in DUNGEON_LEVELS:
		update_power_up_states()
	else:
		print("Unknown level: ", new_level)
