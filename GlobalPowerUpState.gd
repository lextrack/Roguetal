extends Node

var double_damage_active = false
var double_speed_active = false

func reset_power_ups():
	double_damage_active = false
	double_speed_active = false

func activate_double_damage():
	double_damage_active = true

func activate_double_speed():
	double_speed_active = true
