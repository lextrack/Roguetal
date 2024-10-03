extends CanvasLayer

const HEART_ROW_SIZE = 8
const HEART_OFFSET = 16
const MAX_HEARTS = 4

@onready var heart_container = $heart
@onready var heart_texture = $heart.texture
@onready var kill_count_label: Label = $kill_count_label
@onready var time_played_label: Label = $time_played_label
@onready var highest_streak_label: Label = $highest_streak_label
@onready var ammo_amount: Label = $ammo_amount

var previous_kill_count = 0
var previous_highest_streak = 0

func _ready() -> void:
	create_hearts()
	time_played_label.modulate.a = 0

func create_hearts():
	for i in range(MAX_HEARTS):
		var new_heart = Sprite2D.new()
		new_heart.texture = heart_texture
		new_heart.hframes = $heart.hframes
		heart_container.add_child(new_heart)

func _process(delta: float) -> void:
	ammo_amount.text = str(player_data.ammo)
	update_kill_count()
	update_time_played(delta)
	update_highest_streak()
	update_hearts()

func update_kill_count():
	if player_data.kill_count != previous_kill_count:
		kill_count_label.text = "Kills: " + str(player_data.kill_count)
		animate_kill_count()
		previous_kill_count = player_data.kill_count

func update_time_played(delta: float):
	player_data.time_played += delta
	time_played_label.text = "Time: " + format_time(player_data.time_played)
	if time_played_label.modulate.a < 1:
		time_played_label.modulate.a += delta

func update_highest_streak():
	if player_data.highest_kill_streak != previous_highest_streak:
		highest_streak_label.text = "Highest Streak: " + str(player_data.highest_kill_streak)
		if player_data.highest_kill_streak > previous_highest_streak:
			animate_highest_streak()
		previous_highest_streak = player_data.highest_kill_streak

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

func animate_kill_count():
	var tween = create_tween()
	tween.tween_property(kill_count_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(kill_count_label, "scale", Vector2(1, 1), 0.1)

func animate_highest_streak():
	var tween = create_tween()
	tween.tween_property(highest_streak_label, "scale", Vector2(0, 0), 0)
	tween.tween_property(highest_streak_label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(highest_streak_label, "scale", Vector2(1, 1), 0.2)

func reset_animations():
	kill_count_label.scale = Vector2(1, 1)
	highest_streak_label.scale = Vector2(1, 1)
	time_played_label.modulate.a = 0
