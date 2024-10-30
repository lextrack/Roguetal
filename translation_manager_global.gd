extends Node

signal language_changed

var current_language: String = "en-us"
var translations: Dictionary = {}

func _ready() -> void:
	load_translations()

func load_translations() -> void:
	var json_file = FileAccess.open("res://Dialogues/hud_texts.json", FileAccess.READ)
	if json_file:
		var json_text = json_file.get_as_text()
		var json = JSON.parse_string(json_text)
		if json:
			translations = json
	else:
		print("Failed to load translations file")

func get_text(key: String) -> String:
	if translations.has(current_language) and translations[current_language].has(key):
		return translations[current_language][key]
	return key

func set_language(lang_code: String) -> void:
	if translations.has(lang_code):
		current_language = lang_code
		emit_signal("language_changed")
