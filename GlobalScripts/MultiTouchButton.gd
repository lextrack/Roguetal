extends TextureButton

signal touch_pressed

var interaction_timer: Timer

@export var delay_time: float = 0.6

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	if name == "InteractButton":
		interaction_timer = Timer.new()
		interaction_timer.one_shot = true
		interaction_timer.wait_time = delay_time
		add_child(interaction_timer)
		interaction_timer.timeout.connect(_on_timer_timeout)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var touch_position = event.position
			if _is_point_inside(touch_position):
				button_pressed = true
				if name == "InteractButton" and interaction_timer != null:
					interaction_timer.start()
				else:
					emit_signal("pressed")
					emit_signal("touch_pressed")
		elif button_pressed:
			button_pressed = false
			if name == "InteractButton" and interaction_timer != null:
				interaction_timer.stop()

func _is_point_inside(point: Vector2) -> bool:
	var local_point = point - global_position
	return Rect2(Vector2.ZERO, size).has_point(local_point)

func _on_timer_timeout() -> void:
	if button_pressed:
		emit_signal("pressed")
		emit_signal("touch_pressed")
