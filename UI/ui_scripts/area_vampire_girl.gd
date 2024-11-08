extends Area2D

var dialogue = []
var rare_dialogues = []
var dialogue_index = 0
var player_in_range = false
var showing_rare_dialogues = false
var rare_dialogue_index = 0
var tween: Tween

# Constantes para las animaciones
const ANIMATION_DURATION = 0.3
const FLOAT_DISTANCE = 10.0
const PANEL_START_SCALE = Vector2(0.8, 0.8)
const PANEL_FINAL_SCALE = Vector2(1.0, 1.0)

# Variable para mantener la posición base del panel
var panel_base_position: Vector2

func _ready() -> void:
	randomize()
	TranslationManager.language_changed.connect(load_dialogues)
	load_dialogues()
	
	# Guardamos la posición inicial del panel
	panel_base_position = $PanelDialogue.position
	
	# Configuración inicial del panel
	$PanelDialogue.scale = PANEL_START_SCALE
	$PanelDialogue.modulate.a = 0
	hide_dialogue()
	
	if Globals.has_shown_intro:
		showing_rare_dialogues = true
		dialogue_index = dialogue.size()

func load_dialogues() -> void:
	var file = FileAccess.open("res://Dialogues/dialogues.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var data = JSON.parse_string(json_string)
		if data:
			var current_lang_dialogues = data[TranslationManager.current_language]
			dialogue = current_lang_dialogues["introductory_dialogues"]
			rare_dialogues = current_lang_dialogues["rare_dialogues"]
			rare_dialogues.shuffle()
			
			if $PanelDialogue.visible:
				show_current_dialogue()
		else:
			print("Failed to parse JSON")
		file.close()
	else:
		print("Failed to open file")

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact_player1"):
		show_dialogue()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true
		animate_panel_bounce()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		hide_dialogue()

func show_current_dialogue() -> void:
	if showing_rare_dialogues:
		if rare_dialogues.size() > 0:
			$PanelDialogue/LabelContentDialogue.text = rare_dialogues[max(0, rare_dialogue_index - 1)]
	else:
		if dialogue_index > 0:
			$PanelDialogue/LabelContentDialogue.text = dialogue[dialogue_index - 1]

func show_dialogue():
	if tween:
		tween.kill()
	
	var next_dialogue = ""
	if showing_rare_dialogues:
		if rare_dialogues.size() > 0:
			if rare_dialogue_index >= rare_dialogues.size():
				rare_dialogue_index = 0
				rare_dialogues.shuffle()
			next_dialogue = rare_dialogues[rare_dialogue_index]
			rare_dialogue_index += 1
		else:
			hide_dialogue()
			return
	else:
		if dialogue_index < dialogue.size():
			next_dialogue = dialogue[dialogue_index]
			dialogue_index += 1
			
			if dialogue_index >= dialogue.size():
				Globals.has_shown_intro = true
				showing_rare_dialogues = true
		else:
			showing_rare_dialogues = true
			dialogue_index = 0
			rare_dialogue_index = 0
			show_dialogue()
			return

	$PanelDialogue.visible = true
	animate_dialogue_show(next_dialogue)

func hide_dialogue():
	if tween:
		tween.kill()
	
	# Resetear la posición del panel a la base antes de animar
	$PanelDialogue.position = panel_base_position
	
	tween = create_tween().set_parallel()
	tween.tween_property($PanelDialogue, "modulate:a", 0.0, ANIMATION_DURATION)
	tween.tween_property($PanelDialogue, "position", panel_base_position + Vector2(0, FLOAT_DISTANCE), ANIMATION_DURATION)
	tween.tween_property($PanelDialogue, "scale", PANEL_START_SCALE, ANIMATION_DURATION)
	tween.chain().tween_callback(func(): 
		$PanelDialogue.visible = false
		# Asegurarnos de que el panel vuelve a su posición base
		$PanelDialogue.position = panel_base_position
	)

func animate_dialogue_show(next_text: String):
	if tween:
		tween.kill()
	
	# Resetear a la posición base antes de comenzar la animación
	$PanelDialogue.position = panel_base_position + Vector2(0, FLOAT_DISTANCE)
	$PanelDialogue.scale = PANEL_START_SCALE
	$PanelDialogue.modulate.a = 0
	$PanelDialogue/LabelContentDialogue.text = next_text
	
	tween = create_tween().set_parallel()
	tween.tween_property($PanelDialogue, "modulate:a", 1.0, ANIMATION_DURATION)
	tween.tween_property($PanelDialogue, "position", panel_base_position, ANIMATION_DURATION)
	tween.tween_property($PanelDialogue, "scale", PANEL_FINAL_SCALE, ANIMATION_DURATION)

func animate_panel_bounce():
	if not $PanelDialogue.visible:
		return
	
	if tween:
		tween.kill()
	
	tween = create_tween().set_parallel()
	tween.tween_property($PanelDialogue, "scale", PANEL_FINAL_SCALE * 1.1, 0.1)
	tween.chain().tween_property($PanelDialogue, "scale", PANEL_FINAL_SCALE, 0.1)
