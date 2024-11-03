extends Area2D

var is_using_gamepad = false
var initial_mouse_pos = Vector2.ZERO
var target_position = Vector2.ZERO

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	initial_mouse_pos = get_global_mouse_position()
	target_position = initial_mouse_pos

func _process(delta: float) -> void:
	if not is_using_gamepad:
		visible = true
		
		var config = ConfigFile.new()
		var mouse_sensitivity = 1.0
		
		if config.load("user://options_settings.cfg") == OK:
			mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 1.0)
		
		var current_mouse_pos = get_global_mouse_position()
		
		var mouse_movement = current_mouse_pos - target_position
		target_position += mouse_movement * mouse_sensitivity
		
		global_position = target_position
		
	else:
		visible = false
