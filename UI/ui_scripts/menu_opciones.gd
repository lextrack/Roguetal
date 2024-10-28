extends Control

@onready var volumen_slider = $PanelOpciones/VBoxContainer/VolumenSlider
@onready var fullscreen_check = $PanelOpciones/VBoxContainer/FullscreenCheck
@onready var resolution_option = $PanelOpciones/VBoxContainer/ResolutionOption
@onready var language_button = $PanelOpciones/VBoxContainer/LanguageButton
@onready var panel_opciones = $PanelOpciones
@onready var options_menu: Label = $PanelOpciones/VBoxContainer/Options
@onready var volume_label_game: Label = $PanelOpciones/VBoxContainer/volume_label
@onready var button_save: Button = $PanelOpciones/VBoxContainer/VBoxContainer/button_save
@onready var button_cancel: Button = $PanelOpciones/VBoxContainer/VBoxContainer/button_cancel

var initial_settings = {}
var has_unsaved_changes = false
var current_selection = 0
var focusable_elements = []

var available_resolutions = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720),
	Vector2i(1024, 576)
]

func _ready():
	if !_verify_required_nodes():
		return
	
	_setup_volume_slider()
	_setup_resolution_option() 
	_connect_signals()
	load_config()
	update_language_button_text()
	_store_initial_settings()
	
	focusable_elements = [
		volumen_slider,
		fullscreen_check,
		language_button,
		resolution_option,
		button_save,
		button_cancel
	]
	
	for element in focusable_elements:
		if element:
			element.focus_entered.connect(_on_element_focused)
	
	hide()
	
	visibility_changed.connect(_on_visibility_changed)

func _on_hide_menu() -> void:
	for element in focusable_elements:
		if element:
			element.release_focus()

func _on_show_menu() -> void:
	current_selection = 0
	if focusable_elements.size() > 0:
		update_selection()

func _on_visibility_changed() -> void:
	if visible:
		_on_show_menu()
	else:
		_on_hide_menu()
		
func _process(_delta: float) -> void:
	if visible:
		handle_menu_navigation()

func handle_menu_navigation() -> void:
	var old_selection = current_selection
	
	if Input.is_action_just_pressed("ui_down_pause"):
		current_selection = (current_selection + 1) % focusable_elements.size()
	elif Input.is_action_just_pressed("ui_up_pause"):
		current_selection = (current_selection - 1 + focusable_elements.size()) % focusable_elements.size()
	elif Input.is_action_just_pressed("ui_left_pause"):
		if current_selection == 0:  # Volumen Slider
			volumen_slider.value -= volumen_slider.step
	elif Input.is_action_just_pressed("ui_right_pause"):
		if current_selection == 0:  # Volumen Slider
			volumen_slider.value += volumen_slider.step
	elif Input.is_action_just_pressed("ui_accept_menu_pause"):
		_handle_element_activation()
	
	if old_selection != current_selection:
		update_selection()

func update_selection() -> void:
	for i in range(focusable_elements.size()):
		var element = focusable_elements[i]
		if element:
			if i == current_selection:
				element.grab_focus()
			else:
				element.release_focus()

func _handle_element_activation() -> void:
	var current_element = focusable_elements[current_selection]
	
	match current_element:
		volumen_slider:
			pass
		fullscreen_check:
			fullscreen_check.button_pressed = !fullscreen_check.button_pressed
		language_button:
			_on_language_button_pressed()
		button_save:
			_on_button_save_pressed()
		button_cancel:
			_on_button_cancel_pressed()

func _on_element_focused() -> void:
	for i in range(focusable_elements.size()):
		if focusable_elements[i].has_focus():
			current_selection = i
			break

func _setup_resolution_option() -> void:
	if resolution_option:
		resolution_option.clear()
		for resolution in available_resolutions:
			resolution_option.add_item("%dx%d" % [resolution.x, resolution.y])

func _verify_required_nodes() -> bool:
	var required_nodes = {
		"Options Label": options_menu,
		"VolumenSlider": volumen_slider,
		"FullscreenCheck": fullscreen_check,
		"ResolutionOption": resolution_option,
		"LanguageButton": language_button,
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
	if !volumen_slider.value_changed.is_connected(_on_volumen_slider_value_changed):
		volumen_slider.value_changed.connect(_on_volumen_slider_value_changed)
	
	if !fullscreen_check.toggled.is_connected(_on_fullscreen_check_toggled):
		fullscreen_check.toggled.connect(_on_fullscreen_check_toggled)
	
	if !language_button.pressed.is_connected(_on_language_button_pressed):
		language_button.pressed.connect(_on_language_button_pressed)
	
	# Nueva conexión para el selector de resoluciones
	if resolution_option and !resolution_option.item_selected.is_connected(_on_resolution_selected):
		resolution_option.item_selected.connect(_on_resolution_selected)

# Nueva función para manejar el cambio de resolución
func _on_resolution_selected(index: int) -> void:
	if index >= 0 && index < available_resolutions.size():
		var new_resolution = available_resolutions[index]
		if !fullscreen_check.button_pressed:
			get_window().mode = Window.MODE_WINDOWED
			get_window().size = new_resolution
			# Centrar la ventana
			var screen_size = DisplayServer.screen_get_size()
			get_window().position = Vector2i(
				(screen_size.x - new_resolution.x) / 2,
				(screen_size.y - new_resolution.y) / 2
			)
	_on_setting_changed()

func _setup_volume_slider() -> void:
	volumen_slider.min_value = 0.0
	volumen_slider.max_value = 1.0
	volumen_slider.step = 0.1
	volumen_slider.value_changed.connect(_update_volume_label)

func _store_initial_settings() -> void:
	if volumen_slider and fullscreen_check and resolution_option:
		initial_settings = {
			"volumen": volumen_slider.value,
			"fullscreen": fullscreen_check.button_pressed,
			"resolution": resolution_option.selected,
			"language": TranslationManager.current_language
		}

func _check_for_changes() -> bool:
	if !initial_settings.has("volumen"):
		return false
		
	return (
		initial_settings["volumen"] != volumen_slider.value or
		initial_settings["fullscreen"] != fullscreen_check.button_pressed or
		initial_settings["resolution"] != resolution_option.selected or
		initial_settings["language"] != TranslationManager.current_language
	)

func _on_setting_changed(_value = null) -> void:
	has_unsaved_changes = _check_for_changes()
	_update_save_button()

func _update_save_button() -> void:
	button_save.disabled = !has_unsaved_changes

func _update_volume_label(value: float) -> void:
	volume_label_game.text = TranslationManager.get_text("volume_label_game") + " " + str(int(value * 100)) + "%"

func _on_volumen_slider_value_changed(value: float) -> void:
	value = clamp(value, 0.0, 1.0)
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	_on_setting_changed()

func _on_fullscreen_check_toggled(button_pressed: bool) -> void:
	if button_pressed:
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED
		# Aplicar la resolución actual cuando salimos de pantalla completa
		var current_res = available_resolutions[resolution_option.selected]
		get_window().size = current_res
		# Centrar la ventana
		var screen_size = DisplayServer.screen_get_size()
		get_window().position = Vector2i(
			(screen_size.x - current_res.x) / 2,
			(screen_size.y - current_res.y) / 2
		)
	_on_setting_changed()

func _on_language_button_pressed() -> void:
	var new_language = "en"
	match TranslationManager.current_language:
		"en": new_language = "es"
		"es": new_language = "zh"
		"zh": new_language = "en"
	
	TranslationManager.set_language(new_language)
	update_language_button_text()
	_on_setting_changed()

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
	pass

func save_config() -> void:
	var config = ConfigFile.new()
	
	config.set_value("audio", "volumen", volumen_slider.value)
	config.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	config.set_value("video", "resolution_index", resolution_option.selected)
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

func _apply_config(config: ConfigFile) -> void:
	# Primero configuramos la resolución y el modo de pantalla
	if resolution_option:
		var res_index = config.get_value("video", "resolution_index", 0)
		resolution_option.selected = clamp(res_index, 0, available_resolutions.size() - 1)
	
	if fullscreen_check:
		var fs = config.get_value("video", "fullscreen", false)
		fullscreen_check.button_pressed = fs
		
		if fs:
			get_window().mode = Window.MODE_FULLSCREEN
		else:
			get_window().mode = Window.MODE_WINDOWED
			var current_res = available_resolutions[resolution_option.selected]
			get_window().size = current_res
			# Centrar la ventana
			var screen_size = DisplayServer.screen_get_size()
			get_window().position = Vector2i(
				(screen_size.x - current_res.x) / 2,
				(screen_size.y - current_res.y) / 2
			)
	
	# Configuraciones de audio y lenguaje
	if volumen_slider:
		var vol = config.get_value("audio", "volumen", 1.0)
		volumen_slider.value = vol
		_on_volumen_slider_value_changed(vol)
	
	var saved_language = config.get_value("language", "current", "en")
	TranslationManager.set_language(saved_language)
	update_language_button_text()

func _apply_default_config() -> void:
	# Configurar resolución por defecto
	if resolution_option:
		resolution_option.selected = 0
	
	# Configurar modo ventana por defecto
	if fullscreen_check:
		fullscreen_check.button_pressed = false
		get_window().mode = Window.MODE_WINDOWED
		
		var default_res = available_resolutions[0]
		get_window().size = default_res
		# Centrar la ventana
		var screen_size = DisplayServer.screen_get_size()
		get_window().position = Vector2i(
			(screen_size.x - default_res.x) / 2,
			(screen_size.y - default_res.y) / 2
		)
	
	# Configuraciones de audio y lenguaje
	if volumen_slider:
		volumen_slider.value = 1.0
		_on_volumen_slider_value_changed(1.0)
	
	TranslationManager.set_language("en")
	update_language_button_text()

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
