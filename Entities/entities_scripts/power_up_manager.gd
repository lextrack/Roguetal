extends Node

signal double_damage_changed(active: bool)
signal double_speed_changed(active: bool)

func _ready():
	if GlobalPowerUpState.double_damage_active:
		emit_signal("double_damage_changed", true)
	if GlobalPowerUpState.double_speed_active:
		emit_signal("double_speed_changed", true)

func activate_double_damage() -> void:
	GlobalPowerUpState.activate_double_damage()
	emit_signal("double_damage_changed", true)

func activate_double_speed() -> void:
	GlobalPowerUpState.activate_double_speed()
	emit_signal("double_speed_changed", true)

func reset_power_ups() -> void:
	GlobalPowerUpState.reset_power_ups()
	emit_signal("double_damage_changed", false)
	emit_signal("double_speed_changed", false)

func is_double_damage_active() -> bool:
	return GlobalPowerUpState.double_damage_active

func is_double_speed_active() -> bool:
	return GlobalPowerUpState.double_speed_active
