extends CanvasLayer

signal loading_finished

@onready var loading_spinner: TextureRect = $Control/LoadingSpinner
@onready var tip_label: Label = $Control/TipLabel

var next_scene: String = ""
var tips = {}
var used_tips = []

func _ready():
	if loading_spinner:
		loading_spinner.pivot_offset = loading_spinner.size / 2
	
	randomize()
	
	TranslationManager.language_changed.connect(reload_tips)
	load_tips()
	change_tip()
	set_process(false)

func load_tips():
	if FileAccess.file_exists("res://Dialogues/tips.json"):
		var json_as_text = FileAccess.open("res://Dialogues/tips.json", FileAccess.READ)
		var json_as_dict = JSON.parse_string(json_as_text.get_as_text())
		if json_as_dict:
			tips = json_as_dict
			used_tips.clear()
	else:
		push_error("Error: No se pudo encontrar el archivo tips.json")
		tips = {
			"es": {"tips": ["Cargando..."]},
			"en": {"tips": ["Loading..."]}
		}

func reload_tips():
	used_tips.clear()
	change_tip()

func get_current_tips() -> Array:
	var current_lang = TranslationManager.current_language
	if tips.has(current_lang) and tips[current_lang].has("tips"):
		return tips[current_lang]["tips"]
	return ["Loading..."]  # Fallback tip

func change_tip():
	if tip_label:
		var current_tips = get_current_tips()
		
		if current_tips.size() == used_tips.size():
			used_tips.clear()
		
		var available_tips = current_tips.filter(func(tip): return tip not in used_tips)
		if available_tips.is_empty():
			available_tips = current_tips
			used_tips.clear()
		
		var new_tip = available_tips[randi() % available_tips.size()]
		tip_label.text = new_tip
		used_tips.append(new_tip)
	
	if get_tree().has_meta("tip_timer"):
		var old_timer = get_tree().get_meta("tip_timer")
		if old_timer and old_timer.timeout.is_connected(change_tip):
			old_timer.timeout.disconnect(change_tip)
	
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(change_tip)
	get_tree().set_meta("tip_timer", timer)

func _process(delta):
	if loading_spinner:
		loading_spinner.rotation += delta * 2
	
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(next_scene, progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass
		ResourceLoader.THREAD_LOAD_LOADED:
			finish_loading()
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load scene: " + next_scene)
			set_process(false)

func load_scene(path: String):
	if path.is_empty():
		push_error("Invalid scene path provided")
		return
	
	next_scene = path
	var error = ResourceLoader.load_threaded_request(next_scene)
	if error != OK:
		push_error("Failed to start loading scene: " + next_scene)
		return
	
	set_process(true)

func finish_loading():
	set_process(false)
	if loading_spinner:
		loading_spinner.rotation = 0
	var new_scene = ResourceLoader.load_threaded_get(next_scene)
	if new_scene:
		get_tree().change_scene_to_packed(new_scene)
		queue_free()
		emit_signal("loading_finished")
	else:
		push_error("Failed to get loaded scene: " + next_scene)

func _exit_tree():
	if not next_scene.is_empty():
		if ResourceLoader.load_threaded_get_status(next_scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			ResourceLoader.load_threaded_get(next_scene)
