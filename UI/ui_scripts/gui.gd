extends CanvasLayer

const HEART_ROW_SIZE = 8
const HEART_OFFSET = 16

func _ready() -> void:
	for i in range(player_data.health):
		var new_heart = Sprite2D.new()
		new_heart.texture = $heart.texture
		new_heart.hframes = $heart.hframes
		$heart.add_child(new_heart)

func _process(delta: float) -> void:
	$ammo_amount.text = var_to_str(player_data.ammo)
	
	for heart in $heart.get_children():
		var index = heart.get_index()
		var x = (index % HEART_ROW_SIZE) * HEART_OFFSET
		var y = (index / HEART_ROW_SIZE) * HEART_OFFSET
		heart.position = Vector2(x, y)
		
		var last_heart = floor(player_data.health)
		if index > last_heart:
			heart.frame = 0
		if index == last_heart:
			heart.frame = (player_data.health - last_heart) * 4 
		if index < last_heart:
			heart.frame = 4
