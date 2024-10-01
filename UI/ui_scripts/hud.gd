extends CanvasLayer

const HEART_ROW_SIZE = 8
const HEART_OFFSET = 16
const MAX_HEARTS = 4

@onready var heart_container = $heart
@onready var heart_texture = $heart.texture
@onready var kill_count_label: Label = $kill_count_label

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
	kill_count_label.text = "Kills: " + str(player_data.kill_count)
	update_hearts()

func update_hearts():
	var health = player_data.health
	for i in range(MAX_HEARTS):
		var heart = heart_container.get_child(i)
		
		if i < int(health):
			heart.frame = 4
		elif i == int(health) and (health - int(health)) > 0:
			heart.frame = 2
		else:
			heart.frame = 0

		var x = (i % HEART_ROW_SIZE) * HEART_OFFSET
		var y = (i / HEART_ROW_SIZE) * HEART_OFFSET
		heart.position = Vector2(x, y)
