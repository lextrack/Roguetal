extends Node

static var current_language: String = "en"
static var translations: Dictionary = {}

func _ready() -> void:
	# Si las traducciones ya están cargadas, no cargarlas de nuevo
	if translations.is_empty():
		load_translations()
	else:
		# Si ya hay traducciones, solo actualizar la UI
		get_parent().update_translations()

func load_translations() -> void:
	var json_file = FileAccess.open("res://Dialogues/hud_texts.json", FileAccess.READ)
	if json_file:
		var json_text = json_file.get_as_text()
		var json = JSON.parse_string(json_text)
		if json:
			translations = json
			print("Translations loaded: ", translations)
	else:
		print("Failed to load translations file")

func get_text(key: String) -> String:
	if translations.has(current_language) and translations[current_language].has(key):
		return translations[current_language][key]
	return key

func set_language(lang_code: String) -> void:
	if translations.has(lang_code):
		current_language = lang_code
		get_parent().update_translations()
