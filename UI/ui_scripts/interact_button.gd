extends TextureButton

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var touch_position = event.position
		if get_global_rect().has_point(touch_position):
			get_viewport().set_input_as_handled()
			button_pressed = true
			pressed.emit()
