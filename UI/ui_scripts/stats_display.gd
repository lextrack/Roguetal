extends Control

@onready var stats_container = $MarginContainer/PanelContainer/StatsContainer
@onready var title_label: Label = $MarginContainer/PanelContainer/StatsContainer/TitleLabel
@onready var total_kills_label: Label = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/TotalKillsLabel
@onready var total_kills_value: Label = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/TotalKillsValue
@onready var total_time_label: Label = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/TotalTimeLabel
@onready var total_time_value: Label = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/TotalTimeValue
@onready var highest_streak_label: Label = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/HighestStreakLabel
@onready var highest_streak_value: Label = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/HighestStreakValue
@onready var games_played_label: Label = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/GamesPlayedLabel
@onready var games_played_value: Label = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/GamesPlayedValue
@onready var avg_time_label: Label = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/AvgTimeLabel
@onready var avg_time_value: Label = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/AvgTimeValue
@onready var avg_kills_label: Label = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/AvgKillsLabel
@onready var avg_kills_value: Label = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/AvgKillsValue
@onready var back_button: Button = $MarginContainer/PanelContainer/StatsContainer/StatsGrid/BackButton

var stats_visible = false
var initial_stats_position: Vector2
var title_original_scale: Vector2

var floating_animation: Tween
var initial_y_position: float
const FLOAT_AMPLITUDE := 2.0
const FLOAT_DURATION := 2.0 

func _ready() -> void:
	if !_verify_nodes():
		push_error("Some required nodes are missing in StatsDisplay scene")
		return
	
	initial_stats_position = stats_container.position
	initial_y_position = initial_stats_position.y
	title_original_scale = title_label.scale
	
	hide()
	modulate.a = 0
	stats_container.modulate.a = 0
	stats_container.position.y += 50
	title_label.scale = Vector2.ZERO
	
	await get_tree().process_frame
	TranslationManager.language_changed.connect(update_translations)
	update_translations()
	
func start_floating_animation() -> void:
	if floating_animation:
		floating_animation.kill()
	
	floating_animation = create_tween()
	floating_animation.set_loops()
	floating_animation.set_trans(Tween.TRANS_SINE)
	floating_animation.set_ease(Tween.EASE_IN_OUT)
	
	floating_animation.tween_property(stats_container, "position:y",
		initial_y_position - FLOAT_AMPLITUDE, FLOAT_DURATION * 0.5)
	
	floating_animation.tween_property(stats_container, "position:y",
		initial_y_position + FLOAT_AMPLITUDE, FLOAT_DURATION * 0.5)

func stop_floating_animation() -> void:
	if floating_animation:
		floating_animation.kill()
		floating_animation = null

func show_stats() -> void:
	show()
	update_stats_display()
	animate_entry()
	await get_tree().create_timer(0.5).timeout
	start_floating_animation()
	
func hide_stats() -> void:
	animate_exit()

func _verify_nodes() -> bool:
	return stats_container != null \
		and title_label != null \
		and total_kills_value != null \
		and total_time_value != null \
		and highest_streak_value != null \
		and games_played_value != null \
		and avg_time_value != null \
		and avg_kills_value != null \
		and back_button != null

func update_translations() -> void:
	title_label.text = TranslationManager.get_text("stats_title")
	total_kills_label.text = TranslationManager.get_text("total_kills_label")
	total_time_label.text = TranslationManager.get_text("total_time_label")
	highest_streak_label.text = TranslationManager.get_text("highest_streak_label")
	games_played_label.text = TranslationManager.get_text("games_played_label")
	avg_time_label.text = TranslationManager.get_text("avg_time_label")
	avg_kills_label.text = TranslationManager.get_text("avg_kills_label")
	back_button.text = TranslationManager.get_text("back_button")

func update_stats_display() -> void:
	var stats = StatsManager.get_formatted_stats()
	
	total_kills_value.text = stats.total_kills
	total_time_value.text = stats.total_time
	highest_streak_value.text = stats.highest_streak
	games_played_value.text = stats.games_played
	avg_time_value.text = stats.avg_time
	avg_kills_value.text = stats.avg_kills
	
	StatsManager.save_stats()

func animate_entry() -> void:
	var background_tween = create_tween()
	background_tween.set_trans(Tween.TRANS_CUBIC)
	background_tween.set_ease(Tween.EASE_OUT)
	background_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	var title_tween = create_tween()
	title_tween.set_trans(Tween.TRANS_BACK)
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.tween_property(title_label, "scale", title_original_scale, 0.5)
	
	var stats_tween = create_tween()
	stats_tween.set_trans(Tween.TRANS_CUBIC)
	stats_tween.set_ease(Tween.EASE_OUT)
	stats_tween.tween_property(stats_container, "position", initial_stats_position, 0.5)
	stats_tween.parallel().tween_property(stats_container, "modulate:a", 1.0, 0.5)
	
	stats_visible = true

func animate_exit() -> void:
	if !stats_visible:
		return
	
	stop_floating_animation()
	
	stats_container.position.y = initial_y_position
	
	var background_tween = create_tween()
	background_tween.set_trans(Tween.TRANS_CUBIC)
	background_tween.set_ease(Tween.EASE_IN)
	background_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	var title_tween = create_tween()
	title_tween.set_trans(Tween.TRANS_BACK)
	title_tween.set_ease(Tween.EASE_IN)
	title_tween.tween_property(title_label, "scale", Vector2.ZERO, 0.3)
	
	var stats_tween = create_tween()
	stats_tween.set_trans(Tween.TRANS_CUBIC)
	stats_tween.set_ease(Tween.EASE_IN)
	stats_tween.tween_property(stats_container, "position:y", initial_stats_position.y + 50, 0.3)
	stats_tween.parallel().tween_property(stats_container, "modulate:a", 0.0, 0.3)
	
	stats_visible = false
	
	await stats_tween.finished
	hide()

func _on_back_button_pressed() -> void:
	animate_button(back_button)
	hide_stats()

func animate_button(button: Button) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_back_popup"):
		_on_back_button_pressed()
