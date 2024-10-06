# SCRIPT POWERUP MANAGER

extends Node

signal double_damage_changed(active: bool)
signal double_speed_changed(active: bool)

const DOUBLE_DAMAGE_DURATION = 30.0
const DOUBLE_SPEED_DURATION = 30.0

var double_damage_active = false
var double_damage_timer = 0.0
var double_speed_active = false
var double_speed_timer = 0.0

func _process(delta: float) -> void:
	process_double_damage(delta)
	process_double_speed(delta)

func process_double_damage(delta: float) -> void:
	if double_damage_active:
		double_damage_timer -= delta
		if double_damage_timer <= 0:
			deactivate_double_damage()

func process_double_speed(delta: float) -> void:
	if double_speed_active:
		double_speed_timer -= delta
		if double_speed_timer <= 0:
			deactivate_double_speed()

func activate_double_damage() -> void:
	double_damage_active = true
	double_damage_timer = DOUBLE_DAMAGE_DURATION
	emit_signal("double_damage_changed", true)

func deactivate_double_damage() -> void:
	double_damage_active = false
	emit_signal("double_damage_changed", false)

func activate_double_speed() -> void:
	double_speed_active = true
	double_speed_timer = DOUBLE_SPEED_DURATION
	emit_signal("double_speed_changed", true)

func deactivate_double_speed() -> void:
	double_speed_active = false
	emit_signal("double_speed_changed", false)

func is_double_damage_active() -> bool:
	return double_damage_active

func is_double_speed_active() -> bool:
	return double_speed_active

func get_double_damage_timer() -> float:
	return double_damage_timer

func get_double_speed_timer() -> float:
	return double_speed_timer
