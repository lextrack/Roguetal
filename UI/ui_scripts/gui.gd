extends CanvasLayer

const HEART_ROW_SIZE = 8
const HEART_OFFSET = 16
const MAX_HEARTS = 4

@onready var heart_container = $heart
@onready var heart_texture = $heart.texture

func _ready() -> void:
	create_hearts()

func create_hearts():
	for i in range(MAX_HEARTS):
		var new_heart = Sprite2D.new()
		new_heart.texture = heart_texture
		new_heart.hframes = $heart.hframes
		heart_container.add_child(new_heart)

func _process(delta: float) -> void:
	$ammo_amount.text = var_to_str(player_data.ammo)
	
	update_hearts()

func update_hearts():
	var health = player_data.health
	for i in range(MAX_HEARTS):
		var heart = heart_container.get_child(i)
		
		if i < health:
			heart.frame = 4
		else:
			heart.frame = 0

		var x = (i % HEART_ROW_SIZE) * HEART_OFFSET
		var y = (i / HEART_ROW_SIZE) * HEART_OFFSET
		heart.position = Vector2(x, y)
