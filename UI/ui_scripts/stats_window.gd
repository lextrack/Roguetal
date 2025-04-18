extends Control

@onready var stats_container = $StatsPanel/MarginContainer/VBoxContainer/StatsContainer
@onready var stats_panel = $StatsPanel
@onready var animation_player = $AnimationPlayer
@onready var tween_manager = {}

var is_visible = false
var power_up_manager = null
var update_timer = 0.0
var previous_values = {} 

func _process(delta):
	if is_visible:
		update_timer += delta
		if update_timer >= 0.1:
			update_timer = 0.0
			update_all_stats()
			
func _ready():
	if stats_panel:
		stats_panel.visible = false
		
	if animation_player:
		setup_animations()
	else:
		push_error("AnimationPlayer not found in StatsWindow")
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.power_up_manager:
		power_up_manager = player.power_up_manager
		power_up_manager.connect("power_up_changed", _on_power_up_changed)
		update_all_stats()
		
		TranslationManager.language_changed.connect(update_all_stats)

func setup_animations():
	var animation_lib = AnimationLibrary.new()
	
	var show_animation = Animation.new()
	var track_idx = show_animation.add_track(Animation.TYPE_VALUE)
	show_animation.track_set_path(track_idx, ".:modulate")
	show_animation.track_insert_key(track_idx, 0.0, Color(1, 1, 1, 0))
	show_animation.track_insert_key(track_idx, 0.2, Color(1, 1, 1, 1))
	show_animation.length = 0.2
	
	var hide_animation = Animation.new()
	track_idx = hide_animation.add_track(Animation.TYPE_VALUE)
	hide_animation.track_set_path(track_idx, ".:modulate")
	hide_animation.track_insert_key(track_idx, 0.0, Color(1, 1, 1, 1))
	hide_animation.track_insert_key(track_idx, 0.2, Color(1, 1, 1, 0))
	hide_animation.length = 0.2
	
	animation_lib.add_animation("show", show_animation)
	animation_lib.add_animation("hide", hide_animation)
	
	animation_player.add_animation_library("", animation_lib)

func _input(event):
	if event.is_action_pressed("show_stats"):
		toggle_stats_window()

func toggle_stats_window():
	if is_visible:
		hide_stats()
	else:
		show_stats()

func show_stats():
	if stats_panel:
		stats_panel.visible = true
		if animation_player:
			animation_player.play("show")
		is_visible = true
		update_all_stats()

func hide_stats():
	if animation_player:
		animation_player.play("hide")
		await animation_player.animation_finished
	if stats_panel:
		stats_panel.visible = false
	is_visible = false

func _on_power_up_changed(type: int, multiplier: float):

	update_stat_display(type, multiplier)

func update_all_stats():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.power_up_manager:
		for type in PowerUpTypes.PowerUpType.values():
			var multiplier = player.power_up_manager.get_multiplier(type)
			update_stat_display(type, multiplier)

func update_stat_display(type: int, multiplier: float):
	if not stats_container:
		return
		
	var stat_label = stats_container.get_node_or_null("Stat" + str(type))
	if not stat_label:
		stat_label = Label.new()
		stat_label.name = "Stat" + str(type)
		stats_container.add_child(stat_label)
		
		var label_settings = LabelSettings.new()
		var font = load("res://Fonts/Pixel Azure Bonds.otf")
		label_settings.font = font
		label_settings.font_size = 17
		label_settings.outline_size = 5
		label_settings.outline_color = Color.BLACK
		stat_label.label_settings = label_settings
		
		previous_values[type] = multiplier
		
	var stat_name = get_stat_name(type)
	var formatted_value = format_stat_value(type, multiplier)
	stat_label.text = stat_name + ": " + formatted_value
	
	if type in previous_values and previous_values[type] != multiplier:
		apply_value_change_effect(stat_label, previous_values[type], multiplier)
		
	previous_values[type] = multiplier

func apply_value_change_effect(label: Label, old_value: float, new_value: float):
	if label in tween_manager and tween_manager[label]:
		tween_manager[label].kill()
	
	var tween = create_tween()
	tween_manager[label] = tween
	
	var start_color = Color.GREEN if new_value > old_value else Color.RED
	var end_color = Color.WHITE
	
	tween.tween_property(label, "modulate", start_color, 0.1)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(label, "modulate", end_color, 0.3)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
	
func get_stat_name(type: int) -> String:
	match type:
		PowerUpTypes.PowerUpType.DAMAGE:
			return TranslationManager.get_text("stat_damage")
		PowerUpTypes.PowerUpType.SPEED:
			return TranslationManager.get_text("stat_speed")
		PowerUpTypes.PowerUpType.DEFENSE:
			return TranslationManager.get_text("stat_defense")
		PowerUpTypes.PowerUpType.BULLET_HELL:
			return TranslationManager.get_text("stat_bullet_hell")
		PowerUpTypes.PowerUpType.CRITICAL_CHANCE:
			return TranslationManager.get_text("stat_crit_chance")
		PowerUpTypes.PowerUpType.ENEMY_SLOW:
			return TranslationManager.get_text("stat_enemy_slow")
		PowerUpTypes.PowerUpType.SHOTGUN_FIRE:
			return TranslationManager.get_text("stat_shotgun_fire")
		_:
			return TranslationManager.get_text("stat_unknown")

func format_stat_value(type: int, multiplier: float) -> String:
	match type:
		PowerUpTypes.PowerUpType.BULLET_HELL, PowerUpTypes.PowerUpType.SHOTGUN_FIRE:
			var status = TranslationManager.get_text("status_active") if multiplier >= 1.0 else TranslationManager.get_text("status_inactive")
			return status
		PowerUpTypes.PowerUpType.ENEMY_SLOW:
			var value = str(round((1.0 - multiplier) * 100))
			return value + TranslationManager.get_text("stat_slower")
		_:
			var value = str(round((multiplier - 1.0) * 100))
			return value + TranslationManager.get_text("stat_boost")
