extends Area2D

@onready var portal_enter_sound: AudioStreamPlayer2D = $portal_enter_sound
@onready var loading_screen: PackedScene = preload("res://UI/ui_scenes/loading_screen.tscn")

const LEVELS = [
	"res://Levels/Scenes/main_dungeon.tscn",
	"res://Levels/Scenes/main_dungeon_2.tscn",
	"res://Levels/Scenes/labyrinth_level.tscn"
]

var last_level: String = ""

func _ready() -> void:
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if not is_connected("body_exited", Callable(self, "_on_body_exited")):
		connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.enter_portal("next_level")
		portal_enter_sound.play()
		await portal_enter_sound.finished
		
		var selected_level = select_random_level()
		
		if selected_level != last_level:
			last_level = selected_level
			var loading_instance = loading_screen.instantiate()
			get_tree().current_scene.add_child(loading_instance)
			loading_instance.load_scene(selected_level)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.exit_portal()

func select_random_level() -> String:
	var available_levels = LEVELS.filter(func(level): return level != last_level)
	return available_levels[randi() % available_levels.size()]
