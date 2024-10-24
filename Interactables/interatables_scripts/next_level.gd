extends Area2D

@onready var portal_enter_sound: AudioStreamPlayer2D = $portal_enter_sound
@onready var loading_screen: PackedScene = preload("res://UI/ui_scenes/loading_screen.tscn")

const LEVELS = [
	"res://Levels/Scenes/main_dungeon.tscn",
	"res://Levels/Scenes/main_dungeon_2.tscn",
	"res://Levels/Scenes/labyrinth_level.tscn"
]

var last_level: String = ""

static var level_visits = {
	"res://Levels/Scenes/main_dungeon.tscn": 0,
	"res://Levels/Scenes/main_dungeon_2.tscn": 0,
	"res://Levels/Scenes/labyrinth_level.tscn": 0
}

func _ready() -> void:
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
		
	if not is_connected("body_exited", Callable(self, "_on_body_exited")):
		connect("body_exited", Callable(self, "_on_body_exited"))
	
	var current_scene = get_tree().current_scene.scene_file_path
	if current_scene in level_visits:
		level_visits[current_scene] += 1
		print("Actual scene: ", current_scene)
		print_visit_stats()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.enter_portal("next_level")
		portal_enter_sound.play()
		await portal_enter_sound.finished
		
		var selected_level = select_balanced_level()
		
		if selected_level != last_level:
			last_level = selected_level
			level_visits[selected_level] += 1
			print("Changing to the scene: ", selected_level)
			print_visit_stats()
			var loading_instance = loading_screen.instantiate()
			get_tree().current_scene.add_child(loading_instance)
			loading_instance.load_scene(selected_level)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.exit_portal()

func select_balanced_level() -> String:
	var available_levels = LEVELS.filter(func(level): return level != last_level)
	
	var min_visits = 999999
	var least_visited_levels = []
	
	for level in available_levels:
		if level_visits[level] < min_visits:
			min_visits = level_visits[level]
	
	for level in available_levels:
		if level_visits[level] == min_visits:
			least_visited_levels.append(level)
	
	return least_visited_levels[randi() % least_visited_levels.size()]

func print_visit_stats() -> void:
	print("\nStatistics of level visits:")
	for level in level_visits:
		print("%s: %d visits" % [level.get_file(), level_visits[level]])
	print("")
