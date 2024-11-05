extends RichTextLabel

@export var rise_speed: float = 20.0
@export var lifetime: float = 1.0
@export var fade_start: float = 0.6
@export var shake_amount: float = 5.0
@export var spread_range: float = 30.0

var timer: float = 0.0
var initial_position: Vector2
var offset_x: float = 0.0
var offset_y: float = 0.0
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	modulate.a = 1.0
	rng.randomize()
	
	offset_x = rng.randf_range(-spread_range, spread_range)
	offset_y = rng.randf_range(-10, 10)
	
	initial_position = position
	position.x += offset_x
	position.y += offset_y
	
	var colors = [
		Color.RED,
		Color.MAGENTA,
		Color.BLUE_VIOLET
	]
	
	var random_color = colors[rng.randi() % colors.size()]
	add_theme_color_override("default_color", random_color)
	
	set_process(true)

func _process(delta: float) -> void:
	timer += delta
	
	position.y -= rise_speed * delta
	position.x = initial_position.x + offset_x + sin(timer * 10) * shake_amount
	
	if timer >= fade_start:
		modulate.a = 1.0 - (timer - fade_start) / (lifetime - fade_start)
	
	if timer >= lifetime:
		queue_free()
