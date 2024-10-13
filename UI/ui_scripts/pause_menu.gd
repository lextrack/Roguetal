extends Control

@onready var resume_button = $PanelContainer/VBoxContainer/Resume
@onready var quit_button = $PanelContainer/VBoxContainer/Quit

var current_selection = 0
var buttons = []
var is_menu_visible = false

func _ready() -> void:
	if resume_button != null:
		buttons.append(resume_button)
	else:
		push_error("The button ResumeButton was not found.")

	if quit_button != null:
		buttons.append(quit_button)
	else:
		push_error("The button QuitButton was not found.")

	if buttons.size() > 0:
		update_selection()
	else:
		push_error("Buttons were not founds.")

func _process(delta: float) -> void:
	toggle_menu_pause()
	if is_menu_visible and buttons.size() > 0:
		handle_menu_navigation()

func resume():
	get_tree().paused = false
	$animation_menu.play_backwards("blur")
	is_menu_visible = false
	hide()

func pause():
	get_tree().paused = true
	$animation_menu.play("blur")
	is_menu_visible = true
	show()
	current_selection = 0
	if buttons.size() > 0:
		update_selection()

func toggle_menu_pause():
	if Input.is_action_just_pressed("esc"):
		if get_tree().paused:
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
