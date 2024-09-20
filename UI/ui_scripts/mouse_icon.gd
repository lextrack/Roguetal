extends Area2D

var is_using_gamepad = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta: float) -> void:
	if not is_using_gamepad:
		visible = true
		global_position = get_global_mouse_position()
	else:
		visible = false
