extends CanvasLayer
signal loading_finished

@onready var loading_spinner: TextureRect = $Control/LoadingSpinner
@onready var tip_label: Label = $Control/TipLabel

var next_scene: String = ""
var tips = [
	"Hi, I'm a loading screen.",
	"Don't give up, use power-ups!",
	"Don't die it's bad for your health",
	"Remember to blink occasionally",
	"Tip: Winning is better than losing. But you can't get any of this here",
	"Did you know? The cake is a lie",
	"Random tips, like the levels of this game",
	"Loading... Cargando... Laden... 加载中... Ładowanie... Caricamento...",
	"Tip: Water is wet, fire is hot",
	"Loading game... and contemplating existence",
	"How much water do you need at day? About 15.5 cups. Little cups."
]

var used_tips = []

func _ready():
	if loading_spinner:
		loading_spinner.pivot_offset = loading_spinner.size / 2
	
	randomize()
	change_tip()
	set_process(false)
	
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

func change_tip():
	if tip_label:
		if tips.size() == used_tips.size():
			used_tips.clear()
		
		var available_tips = tips.filter(func(tip): return tip not in used_tips)
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

func _exit_tree():
	if not next_scene.is_empty():
		if ResourceLoader.load_threaded_get_status(next_scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			ResourceLoader.load_threaded_get(next_scene)
