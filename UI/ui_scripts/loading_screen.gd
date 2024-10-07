extends CanvasLayer

signal loading_finished

var next_scene: String = ""
var progress_bar: TextureProgressBar

func _ready():
	progress_bar = $Control/TextureProgressBar if has_node("Control/TextureProgressBar") else null
	if progress_bar:
		progress_bar.min_value = 0
		progress_bar.max_value = 100
		progress_bar.value = 0
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

func _process(delta):
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(next_scene, progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if progress_bar and not progress.is_empty():
				progress_bar.value = progress[0] * 100
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			var new_scene = ResourceLoader.load_threaded_get(next_scene)
			if new_scene:
				get_tree().change_scene_to_packed(new_scene)
				queue_free()
				emit_signal("loading_finished")
			else:
				push_error("Failed to get loaded scene: " + next_scene)
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load scene: " + next_scene)
			set_process(false)

func _exit_tree():
	if not next_scene.is_empty():
		if ResourceLoader.load_threaded_get_status(next_scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			ResourceLoader.load_threaded_get(next_scene)
