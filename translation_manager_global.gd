extends Node

signal language_changed

var current_language: String = "en"
var translations: Dictionary = {}

func _ready() -> void:
	load_translations()

func load_translations() -> void:
	load_json_file("res://Dialogues/hud_texts.json")
	load_json_file("res://Dialogues/stats_menu.json")
	load_json_file("res://Dialogues/stats_display.json")

func load_json_file(path: String) -> void:
	var json_file = FileAccess.open(path, FileAccess.READ)
	if json_file:
		var json_text = json_file.get_as_text()
		var json = JSON.parse_string(json_text)
		if json:
			for language in json:
				if not translations.has(language):
					translations[language] = {}
				translations[language].merge(json[language])
		else:
			push_error("Failed to parse JSON file: " + path)
	else:
		push_error("Failed to load translations file: " + path)

func get_text(key: String) -> String:
	if translations.has(current_language) and translations[current_language].has(key):
		return translations[current_language][key]
	return key

func set_language(lang_code: String) -> void:
	if translations.has(lang_code):
		current_language = lang_code
		emit_signal("language_changed")
