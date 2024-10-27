extends Control

@onready var options_pause: Button = $PanelContainer/VBoxContainer/Options
@onready var resume_button: Button = $PanelContainer/VBoxContainer/Resume
@onready var quit_button: Button = $PanelContainer/VBoxContainer/Quit
@onready var panel_container: Panel = $PanelContainer
@onready var menu_opciones: Control = $MenuOpciones
@onready var buttons_container = $PanelContainer/VBoxContainer

var current_selection = 0
var buttons = []
var is_menu_visible = false

func _ready() -> void:
	check_buttons_state()
	
	TranslationManager.language_changed.connect(update_translations)
	update_translations()
	
	if menu_opciones:
		menu_opciones.visibility_changed.connect(_on_options_menu_visibility_changed)
	
func check_buttons_state():
	if resume_button != null:
		buttons.append(resume_button)
	else:
		push_error("The button ResumeButton was not found.")
		
	if options_pause != null:
		buttons.append(options_pause)
	else:
		push_error("The button Options was not found.")
	
	if quit_button != null:
		buttons.append(quit_button)
	else:
		push_error("The button QuitButton was not found.")
	
	if buttons.size() > 0:
		update_selection()
	else:
		push_error("Buttons were not founds.")

func update_translations() -> void:
	resume_button.text = TranslationManager.get_text("resume_button")
	options_pause.text = TranslationManager.get_text("options_pause")
	quit_button.text = TranslationManager.get_text("quit_button_pause")

func _process(delta: float) -> void:
	toggle_menu_pause()
	if is_menu_visible and buttons.size() > 0:
		handle_menu_navigation()

func resume() -> void:
	get_tree().paused = false
	$animation_menu.play_backwards("blur")
	is_menu_visible = false
	menu_opciones.hide()
	hide()

func pause():
	get_tree().paused = true
	$animation_menu.play("blur")
	is_menu_visible = true
	show()
	current_selection = 0
	if buttons.size() > 0:
		update_selection()

func toggle_menu_pause() -> void:
	if Input.is_action_just_pressed("esc"):
		if menu_opciones.visible:
			menu_opciones.hide()
		elif get_tree().paused:
			resume()
		else:
			pause()

func handle_menu_navigation():
	if Input.is_action_just_pressed("ui_down_pause"):
		current_selection = (current_selection + 1) % buttons.size()
		update_selection()
	elif Input.is_action_just_pressed("ui_up_pause"):
		current_selection = (current_selection - 1 + buttons.size()) % buttons.size()
		update_selection()
	elif Input.is_action_just_pressed("ui_accept_menu_pause"):
		buttons[current_selection].emit_signal("pressed")

func update_selection():
	for i in range(buttons.size()):
		if buttons[i] != null:
			if i == current_selection:
				buttons[i].grab_focus()
			else:
				buttons[i].release_focus()

func _on_resume_pressed() -> void:
	resume()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_options_pressed() -> void:
	panel_container.hide()
	menu_opciones.show()
	
func _on_options_menu_visibility_changed() -> void:
	if !menu_opciones.visible:
		panel_container.show()
		current_selection = buttons.find(options_pause)
		update_selection()
