extends Node

signal damage_multiplier_changed(multiplier: float)
signal speed_multiplier_changed(multiplier: float)

const DUNGEON_LEVELS = ["main_dungeon", "main_dungeon_2", "labyrinth_level"]

func _ready():
	update_power_up_states()

func update_power_up_states() -> void:
	emit_signal("damage_multiplier_changed", GlobalPowerUpState.get_damage_multiplier())
	emit_signal("speed_multiplier_changed", GlobalPowerUpState.get_speed_multiplier())

func activate_double_damage() -> void:
	GlobalPowerUpState.activate_double_damage()
	emit_signal("damage_multiplier_changed", GlobalPowerUpState.get_damage_multiplier())

func activate_double_speed() -> void:
	GlobalPowerUpState.activate_double_speed()
	emit_signal("speed_multiplier_changed", GlobalPowerUpState.get_speed_multiplier())

func reset_power_ups() -> void:
	GlobalPowerUpState.reset_power_ups()
	update_power_up_states()

func get_damage_multiplier() -> float:
	return GlobalPowerUpState.get_damage_multiplier()

func get_speed_multiplier() -> float:
	return GlobalPowerUpState.get_speed_multiplier()

func handle_level_transition(new_level: String) -> void:
	if new_level == "main_world":
		reset_power_ups()
	elif new_level in DUNGEON_LEVELS:
		update_power_up_states()
	else:
		print("Unknown level: ", new_level)
