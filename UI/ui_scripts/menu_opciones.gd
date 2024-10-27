extends Control

@onready var volumen_slider = $PanelOpciones/VBoxContainer/VolumenSlider
@onready var fullscreen_check = $PanelOpciones/VBoxContainer/FullscreenCheck
@onready var language_button = $PanelOpciones/VBoxContainer/LanguageButton
@onready var panel_opciones = $PanelOpciones
@onready var options_menu: Label = $PanelOpciones/VBoxContainer/Options
@onready var volume_label_game: Label = $PanelOpciones/VBoxContainer/volume_label
@onready var button_save: Button = $PanelOpciones/VBoxContainer/HBoxContainer/button_save
@onready var button_cancel: Button = $PanelOpciones/VBoxContainer/HBoxContainer/button_cancel

var initial_settings = {}
var has_unsaved_changes = false

func _ready():
	if !_verify_required_nodes():
		return
		
	_connect_signals()
	_setup_volume_slider()
	load_config()
	update_language_button_text()
	_store_initial_settings()

func _verify_required_nodes() -> bool:
	var required_nodes = {
		"VolumenSlider": volumen_slider,
		"FullscreenCheck": fullscreen_check,
		"LanguageButton": language_button,
		"Options Label": options_menu,
		"Volume Label": volume_label_game,
		"Save Button": button_save,
		"Cancel Button": button_cancel
	}
	
	for node_name in required_nodes:
		if !required_nodes[node_name]:
			push_error("%s not found!" % node_name)
			return false
	return true

func _connect_signals() -> void:
	volumen_slider.value_changed.connect(_on_volumen_slider_value_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_check_toggled)
	language_button.pressed.connect(_on_language_button_pressed)
	
	volumen_slider.value_changed.connect(_on_setting_changed)
	fullscreen_check.toggled.connect(_on_setting_changed)
	language_button.pressed.connect(_on_setting_changed)

func _setup_volume_slider() -> void:
	volumen_slider.min_value = 0.0
	volumen_slider.max_value = 1.0
	volumen_slider.step = 0.1
	volumen_slider.value_changed.connect(_update_volume_label)

func _store_initial_settings() -> void:
	initial_settings = {
		"volume": volumen_slider.value,
		"fullscreen": fullscreen_check.button_pressed,
		"language": TranslationManager.current_language
	}

func _on_setting_changed(_value = null) -> void:
	has_unsaved_changes = true
	_update_save_button()

func _update_save_button() -> void:
	button_save.disabled = !has_unsaved_changes

func _update_volume_label(value: float) -> void:
	volume_label_game.text = TranslationManager.get_text("volume_label_game") + " " + str(int(value * 100)) + "%"

func _on_volumen_slider_value_changed(value: float) -> void:
	value = clamp(value, 0.0, 1.0)
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _on_fullscreen_check_toggled(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_language_button_pressed() -> void:
	var new_language = "en"
	match TranslationManager.current_language:
		"en": new_language = "es"
		"es": new_language = "zh"
		"zh": new_language = "en"
	
	TranslationManager.set_language(new_language)
	update_language_button_text()

func update_language_button_text() -> void:
	if language_button:
		language_button.text = TranslationManager.get_text("language_button")
	
	fullscreen_check.text = TranslationManager.get_text("fullscreen_check")
	options_menu.text = TranslationManager.get_text("options_menu")
	_update_volume_label(volumen_slider.value)
	button_save.text = TranslationManager.get_text("button_save")
	button_cancel.text = TranslationManager.get_text("button_cancel")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if has_unsaved_changes:
			_show_discard_changes_dialog()
		else:
			hide()

func _show_discard_changes_dialog() -> void:
	# Aquí podrías mostrar un diálogo de confirmación
	print("¿Deseas descartar los cambios?")

func save_config() -> void:
	var config = ConfigFile.new()
	
	config.set_value("audio", "volumen", volumen_slider.value)
	config.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	config.set_value("language", "current", TranslationManager.current_language)
	
	var err = config.save("user://configuraciones.cfg")
	if err != OK:
		push_error("Error saving the config file: " + str(err))
	else:
		has_unsaved_changes = false
		_update_save_button()
		_store_initial_settings()

func load_config() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://configuraciones.cfg")
	
	if err == OK:
		_apply_config(config)
	else:
		_apply_default_config()
	
	has_unsaved_changes = false
	_update_save_button()

func _apply_config(config: ConfigFile) -> void:
	if volumen_slider:
		var vol = config.get_value("audio", "volumen", 1.0)
		volumen_slider.value = vol
		_on_volumen_slider_value_changed(vol)
	
	if fullscreen_check:
		var fs = config.get_value("video", "fullscreen", false)
		fullscreen_check.button_pressed = fs
		_on_fullscreen_check_toggled(fs)
		
	var saved_language = config.get_value("language", "current", "en")
	TranslationManager.set_language(saved_language)

func _apply_default_config() -> void:
	if volumen_slider:
		volumen_slider.value = 1.0
	if fullscreen_check:
		fullscreen_check.button_pressed = false
	TranslationManager.set_language("en")

func _on_button_save_pressed() -> void:
	if !_verify_required_nodes():
		return
	
	save_config()
	hide()

func _on_button_cancel_pressed() -> void:
	if has_unsaved_changes:
		_show_discard_changes_dialog()
	load_config()
	hide()
