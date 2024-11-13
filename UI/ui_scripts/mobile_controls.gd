extends CanvasLayer

signal movement_vector_changed(vector: Vector2)
signal aim_vector_changed(vector: Vector2)
signal shooting_started
signal shooting_ended
signal weapon_switch_pressed
signal pause_button_pressed
signal stats_button_pressed
signal interact_button_pressed

@onready var movement_stick = $MovementStick
@onready var aim_stick = $AimStick
@onready var weapon_switch_button = $WeaponSwitchButton
@onready var pause_button = $PauseButton
@onready var stats_button = $StatsButton
@onready var interact_button = $InteractButton

func _ready() -> void:
	movement_stick.connect("analog_value_changed", Callable(self, "_on_movement_changed"))
	aim_stick.connect("analog_value_changed", Callable(self, "_on_aim_changed"))
	aim_stick.connect("shooting_started", Callable(self, "_on_shooting_started"))
	aim_stick.connect("shooting_ended", Callable(self, "_on_shooting_ended"))
	weapon_switch_button.connect("pressed", Callable(self, "_on_weapon_switch_pressed"))
	pause_button.connect("pressed", Callable(self, "_on_pause_button_pressed"))
	stats_button.connect("pressed", Callable(self, "_on_stats_button_pressed"))
	interact_button.connect("pressed", Callable(self, "_on_interact_pressed"))
	
	aim_stick.is_shooting_stick = true
	
	for control in [movement_stick, aim_stick, weapon_switch_button,
		pause_button, stats_button, interact_button]:
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	
	interact_button.visible = false

func _on_movement_changed(vector: Vector2) -> void:
	emit_signal("movement_vector_changed", vector)

func _on_aim_changed(vector: Vector2) -> void:
	emit_signal("aim_vector_changed", vector)

func _on_shooting_started() -> void:
	emit_signal("shooting_started")

func _on_shooting_ended() -> void:
	emit_signal("shooting_ended")

func _on_weapon_switch_pressed() -> void:
	emit_signal("weapon_switch_pressed")
	
func _on_pause_button_pressed() -> void:
	emit_signal("pause_button_pressed")
	
func _on_stats_button_pressed() -> void:
	emit_signal("stats_button_pressed")
	
func _on_interact_pressed() -> void:
	emit_signal("interact_button_pressed")

func show_interact_button() -> void:
	interact_button.visible = true
	
func hide_interact_button() -> void:
	interact_button.visible = false
