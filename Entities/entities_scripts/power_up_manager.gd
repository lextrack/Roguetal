extends Node

signal double_damage_changed(active: bool)
signal double_speed_changed(active: bool)

const DUNGEON_LEVELS = ["main_dungeon", "main_dungeon_2", "labyrinth_level"]

func _ready():
	update_power_up_states()
	
func update_power_up_states() -> void:
	emit_signal("double_damage_changed", GlobalPowerUpState.double_damage_active)
	emit_signal("double_speed_changed", GlobalPowerUpState.double_speed_active)

func activate_double_damage() -> void:
	GlobalPowerUpState.activate_double_damage()
	emit_signal("double_damage_changed", true)

func activate_double_speed() -> void:
	GlobalPowerUpState.activate_double_speed()
	emit_signal("double_speed_changed", true)

func reset_power_ups() -> void:
	GlobalPowerUpState.reset_power_ups()
	update_power_up_states()

func is_double_damage_active() -> bool:
	return GlobalPowerUpState.double_damage_active

func is_double_speed_active() -> bool:
	return GlobalPowerUpState.double_speed_active

func handle_level_transition(new_level: String) -> void:
	if new_level == "main_world":
		reset_power_ups()
	elif new_level in DUNGEON_LEVELS:
		update_power_up_states()
	else:
		print("Unkown level: ", new_level)
