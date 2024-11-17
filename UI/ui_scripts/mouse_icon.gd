extends Area2D

@export var vertical_offset: float = 10.0

var is_using_gamepad = false
var initial_mouse_pos = Vector2.ZERO
var target_position = Vector2.ZERO

const CONFIG_PATH = "user://options_settings.cfg"
const DEFAULT_SENSITIVITY = 1.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	initial_mouse_pos = get_global_mouse_position()
	target_position = initial_mouse_pos

func _process(delta: float) -> void:
	if not is_using_gamepad:
		visible = true
		
		var mouse_sensitivity = get_mouse_sensitivity()
		var current_mouse_pos = get_global_mouse_position()
		
		var mouse_movement = current_mouse_pos - target_position
		target_position += mouse_movement * mouse_sensitivity

		global_position = target_position + Vector2(0, vertical_offset)
	else:
		visible = false

func get_mouse_sensitivity() -> float:
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		return config.get_value("controls", "mouse_sensitivity", DEFAULT_SENSITIVITY)
	return DEFAULT_SENSITIVITY
