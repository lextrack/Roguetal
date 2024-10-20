extends Area2D

@onready var enter_portal_sound: AudioStreamPlayer2D = $enter_portal_sound
@onready var loading_screen: PackedScene = preload("res://UI/ui_scenes/loading_screen.tscn")

var last_levels: Array = []
var levels = [
	"res://Levels/Scenes/main_dungeon.tscn",
	"res://Levels/Scenes/main_dungeon_2.tscn",
	"res://Levels/Scenes/labyrinth_level.tscn"
]

func _ready() -> void:
	randomize()

func select_random_level() -> String:
	var available_levels = levels.duplicate()
	
	for level in last_levels:
		if available_levels.has(level):
			available_levels.erase(level)
	
	if available_levels.is_empty():
		available_levels = levels.duplicate()
	
	var selected_level = available_levels[randi() % available_levels.size()]
	
	last_levels.append(selected_level)
	if last_levels.size() > levels.size() / 2:
		last_levels.pop_front()
	
	return selected_level

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.enter_portal()
		enter_portal_sound.play()
		await enter_portal_sound.finished
		
		var selected_level = select_random_level()
		
		var loading_instance = loading_screen.instantiate()
		get_tree().current_scene.add_child(loading_instance)
		loading_instance.load_scene(selected_level)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		body.exit_portal()
