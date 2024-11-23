extends Control

signal analog_value_changed(vector: Vector2)
signal shooting_started
signal shooting_ended

@export var deadzone: float = 0.2
@export var is_shooting_stick: bool = false # False para movimiento, True para disparo

@onready var stick: TextureRect = $Base/Stick
@onready var base: TextureRect = $Base
@onready var neutral_stick_position: Vector2 = stick.position

var touch_index: int = -1
var base_radius: float
var current_vector: Vector2 = Vector2.ZERO
var is_pressed: bool = false
var stick_offset: Vector2
var is_active: bool = false

func _ready() -> void:
	base_radius = base.size.x * 0.5
	stick_offset = stick.size * 0.5
	set_process_input(true)
	mouse_filter = Control.MOUSE_FILTER_PASS
	
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var touch_position = event.position
			if _is_point_inside_area(touch_position) and not is_active:
				touch_index = event.index
				is_pressed = true
				is_active = true
				_update_stick_position(touch_position)
				if is_shooting_stick:
					emit_signal("shooting_started")
		elif event.index == touch_index:
			touch_index = -1
			is_pressed = false
			is_active = false
			current_vector = Vector2.ZERO
			stick.position = neutral_stick_position
			emit_signal("analog_value_changed", current_vector)
			if is_shooting_stick:
				emit_signal("shooting_ended")
				
	elif event is InputEventScreenDrag and event.index == touch_index:
		_update_stick_position(event.position)

func _is_point_inside_area(point: Vector2) -> bool:
	var local_point = point - global_position
	var base_center = base.position + (base.size * 0.5)
	return local_point.distance_to(base_center) < base_radius * 1.2

func _update_stick_position(touch_pos: Vector2) -> void:
	var base_center = base.position + (base.size * 0.5)
	var local_touch = touch_pos - global_position
	
	var relative_vector = local_touch - base_center
	
	var max_distance = base_radius - (stick.size.x * 0.5)
	if relative_vector.length() > max_distance:
		relative_vector = relative_vector.normalized() * max_distance
	
	current_vector = relative_vector / base_radius
	
	stick.position = base_center + relative_vector - stick_offset
	
	if current_vector.length() > deadzone:
		emit_signal("analog_value_changed", current_vector)
	else:
		emit_signal("analog_value_changed", Vector2.ZERO)

func is_being_used() -> bool:
	return is_active
