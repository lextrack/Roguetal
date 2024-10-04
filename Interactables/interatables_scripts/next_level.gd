extends Area2D

@onready var portal_enter_sound: AudioStreamPlayer2D = $portal_enter_sound
@onready var loading_screen: PackedScene = preload("res://UI/ui_scenes/loading_screen.tscn")

var last_level: String = ""
var levels = [
	"res://Levels/Scenes/main_dungeon.tscn",
	"res://Levels/Scenes/main_dungeon_2.tscn",
	"res://Levels/Scenes/labyrinth_level.tscn"
]

func _ready() -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.enter_portal()
		portal_enter_sound.play()
		await portal_enter_sound.finished
		
		levels.shuffle()
		var selected_level = levels[0]
		
		if selected_level != last_level:
			last_level = selected_level
			var loading_instance = loading_screen.instantiate()
			get_tree().current_scene.add_child(loading_instance)
			loading_instance.load_scene(selected_level)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		body.exit_portal()
