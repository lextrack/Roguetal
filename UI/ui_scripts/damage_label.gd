extends RichTextLabel

@export var rise_speed: float = 20.0
@export var lifetime: float = 1.0
@export var fade_start: float = 0.5
@export var shake_amount: float = 6.0

var timer: float = 0.0
var initial_position: Vector2
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	modulate.a = 1.0
	initial_position = position
	rng.randomize()

	var color = Color.RED if rng.randi() % 2 == 0 else Color.DARK_MAGENTA
	add_theme_color_override("default_color", color)
	
	set_process(true)

func _process(delta: float) -> void:
	timer += delta
	
	position.y -= rise_speed * delta
	
	position.x = initial_position.x + sin(timer * 10) * shake_amount
	
	if timer >= fade_start:
		modulate.a = 1.0 - (timer - fade_start) / (lifetime - fade_start)
	
	if timer >= lifetime:
		queue_free()
