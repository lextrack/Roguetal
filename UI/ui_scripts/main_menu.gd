extends Control

@onready var play: Button = $VBoxContainer/Play
@onready var credits: Button = $VBoxContainer/Credits
@onready var quit: Button = $VBoxContainer/Quit
@onready var language: Button = $VBoxContainer/Language
@onready var credits_panel: Panel = $CreditsPanel
@onready var close_credits_button: Button = $CreditsPanel/CloseCreditsButton
@onready var hover_sound: AudioStreamPlayer2D = $HoverSound

var current_selection = 0
var buttons = []
var credits_open = false
var loading_screen_scene = preload("res://UI/ui_scenes/loading_screen.tscn")
var loading_screen: CanvasLayer = null

func _ready() -> void:
	MusicMainMenu.play_music_level()
	credits_panel.hide()
	close_credits_button.connect("pressed", Callable(self, "_on_close_credits_pressed"))
	
	buttons = [play, credits, language, quit]
	
	for button in buttons:
		if button == null:
			push_error("One of the buttons was not found.")
		else:
			button.mouse_entered.connect(Callable(self, "_on_button_hover"))
			button.focus_entered.connect(Callable(self, "_on_button_hover"))
	
	if buttons.size() > 0:
		update_selection()
	else:
		push_error("No buttons were found.")
	
	await get_tree().process_frame
	TranslationManager.language_changed.connect(update_translations)
	update_translations()
	
func update_translations() -> void:
	play.text = TranslationManager.get_text("play_button")
	credits.text = TranslationManager.get_text("credits_button")
	quit.text = TranslationManager.get_text("quit_button")
	language.text = TranslationManager.get_text("language_button")
	close_credits_button.text = TranslationManager.get_text("close_credits_button")

func _on_language_pressed() -> void:
	animate_button(language)
	
	var new_language = "en" if TranslationManager.current_language == "es" else "es"
	TranslationManager.set_language(new_language)

func _process(delta: float) -> void:
	if credits_open:
		handle_credits_input()
	elif buttons.size() > 0:
		handle_menu_navigation()

func _on_play_pressed() -> void:
	animate_button(play)
	await get_tree().create_timer(0.2).timeout
	
	loading_screen = loading_screen_scene.instantiate()
	add_child(loading_screen)
	
	loading_screen.loading_finished.connect(_on_loading_finished)
	
	loading_screen.load_scene("res://Levels/Scenes/main_world.tscn")

func _on_loading_finished() -> void:
	if loading_screen and loading_screen.loading_finished.is_connected(_on_loading_finished):
		loading_screen.loading_finished.disconnect(_on_loading_finished)

func _on_credits_pressed() -> void:
	animate_button(credits)
	await get_tree().create_timer(0.2).timeout
	credits_panel.show()
	credits_open = true

func _on_quit_pressed() -> void:
	animate_button(quit)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func animate_button(button: Button) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_close_credits_pressed() -> void:
	close_credits()

func close_credits() -> void:
	credits_panel.hide()
	credits_open = false

func handle_menu_navigation():
	var old_selection = current_selection
	if Input.is_action_just_pressed("ui_down_pause"):
		current_selection = (current_selection + 1) % buttons.size()
	elif Input.is_action_just_pressed("ui_up_pause"):
		current_selection = (current_selection - 1 + buttons.size()) % buttons.size()
	elif Input.is_action_just_pressed("ui_accept_menu_pause"):
		buttons[current_selection].pressed.emit()
	
	if old_selection != current_selection:
		update_selection()
		play_hover_sound()

func handle_credits_input():
	if Input.is_action_just_pressed("ui_back_popup"):
		close_credits()

func update_selection():
	for i in range(buttons.size()):
		if i == current_selection:
			buttons[i].grab_focus()
		else:
			buttons[i].release_focus()

func play_hover_sound():
	if hover_sound:
		hover_sound.play()

func _on_button_hover():
	play_hover_sound()
