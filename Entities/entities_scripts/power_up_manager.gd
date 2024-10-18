extends Node

signal power_up_changed(type: int, multiplier: float)

const DUNGEON_LEVELS = ["main_dungeon", "main_dungeon_2", "labyrinth_level"]

func _ready():
	if not GlobalPowerUpState.is_connected("power_up_changed", Callable(self, "_on_global_power_up_changed")):
		GlobalPowerUpState.connect("power_up_changed", Callable(self, "_on_global_power_up_changed"))
	update_power_up_states()

func _on_global_power_up_changed(type: int, multiplier: float):
	emit_signal("power_up_changed", type, multiplier)

func update_power_up_states() -> void:
	for type in PowerUpTypes.PowerUpType.values():
		emit_signal("power_up_changed", type, GlobalPowerUpState.get_multiplier(type))

func activate_power_up(type: int) -> void:
	GlobalPowerUpState.activate_power_up(type)
	# La señal se emitirá a través de _on_global_power_up_changed

func reset_power_ups() -> void:
	GlobalPowerUpState.reset_power_ups()
	# Las señales se emitirán a través de _on_global_power_up_changed para cada power-up

func get_multiplier(type: int) -> float:
	return GlobalPowerUpState.get_multiplier(type)

func handle_level_transition(new_level: String) -> void:
	if new_level == "main_world":
		reset_power_ups()
	elif new_level in DUNGEON_LEVELS:
		update_power_up_states()
	else:
		print("Unknown level: ", new_level)
