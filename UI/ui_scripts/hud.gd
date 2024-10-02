extends CanvasLayer

const HEART_ROW_SIZE = 8
const HEART_OFFSET = 16
const MAX_HEARTS = 4

@onready var heart_container = $heart
@onready var heart_texture = $heart.texture
@onready var kill_count_label: Label = $kill_count_label
@onready var time_played_label: Label = $time_played_label
@onready var highest_streak_label: Label = $highest_streak_label

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
	time_played_label.text = "Time: " + format_time(player_data.time_played)
	highest_streak_label.text = "Highest Streak: " + str(player_data.highest_kill_streak)
	update_hearts()
	
	# Update time played
	player_data.time_played += delta

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

func format_time(seconds: float) -> String:
	var minutes = int(seconds / 60)
	var remaining_seconds = int(seconds) % 60
	return "%02d:%02d" % [minutes, remaining_seconds]
