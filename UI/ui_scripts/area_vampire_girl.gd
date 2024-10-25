extends Area2D

var dialogue = []
var rare_dialogues = []
var dialogue_index = 0
var player_in_range = false
var showing_rare_dialogues = false
var rare_dialogue_index = 0

func _ready() -> void:
	randomize()
	TranslationManager.language_changed.connect(load_dialogues)
	load_dialogues()
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
			# Obtener los diálogos en el idioma actual
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
	if showing_rare_dialogues:
		if rare_dialogues.size() > 0:
			if rare_dialogue_index >= rare_dialogues.size():
				rare_dialogue_index = 0
				rare_dialogues.shuffle()
			$PanelDialogue.visible = true
			$PanelDialogue/LabelContentDialogue.text = rare_dialogues[rare_dialogue_index]
			rare_dialogue_index += 1
		else:
			hide_dialogue()
	else:
		if dialogue_index < dialogue.size():
			$PanelDialogue.visible = true
			$PanelDialogue/LabelContentDialogue.text = dialogue[dialogue_index]
			dialogue_index += 1
			
			if dialogue_index >= dialogue.size():
				Globals.has_shown_intro = true
				showing_rare_dialogues = true
		else:
			showing_rare_dialogues = true
			dialogue_index = 0
			rare_dialogue_index = 0
			show_dialogue()

func hide_dialogue():
	$PanelDialogue.visible = false
