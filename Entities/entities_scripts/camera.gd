extends Camera2D

var starting_shaking = false
var shake_intensity: float = 0.0
var shake_dampening: float = 0.0

@onready var camera_shake = $camera_shake

func _ready() -> void:
	Globals.camera = self

func _process(delta: float) -> void:
	if starting_shaking == true:
		offset.x = randi_range(-1, 1) * shake_intensity
		offset.y = randi_range(-1, 1) * shake_intensity
		shake_intensity = lerp(shake_intensity, 0.0, shake_dampening)
	else:
		offset = Vector2(0, 0)

func screen_shake(intensity, duration, dampening):
	shake_intensity = intensity
	camera_shake.wait_time = duration
	shake_dampening = dampening
	starting_shaking = true

func _on_camera_shake_timeout() -> void:
	starting_shaking = false
