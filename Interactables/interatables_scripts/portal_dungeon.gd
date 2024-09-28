extends Area2D

@export var next_scene: String = "res://Levels/Scenes/main_dungeon_2.tscn"
@onready var enter_portal_sound: AudioStreamPlayer2D = $enter_portal_sound


var loading_screen_scene = preload("res://UI/ui_scenes/loading_screen.tscn")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		enter_portal_sound.play()
		await enter_portal_sound.finished
		var loading_screen = loading_screen_scene.instantiate()
		get_tree().root.add_child(loading_screen)
		loading_screen.load_scene(next_scene)
