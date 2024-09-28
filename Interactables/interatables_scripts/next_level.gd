extends Area2D

@onready var portal_enter_sound: AudioStreamPlayer2D = $portal_enter_sound
@onready var loading_screen: PackedScene = preload("res://UI/ui_scenes/loading_screen.tscn")

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	randomize()

var last_level: String = ""

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		portal_enter_sound.play()
		await portal_enter_sound.finished
		var levels = [
			"res://Levels/Scenes/main_dungeon.tscn",
			"res://Levels/Scenes/main_dungeon_2.tscn"
		]
		
		levels.shuffle()
		var selected_level = levels[0]
		var loading_instance = loading_screen.instantiate()
		get_tree().current_scene.add_child(loading_instance)
		loading_instance.load_scene(selected_level)
