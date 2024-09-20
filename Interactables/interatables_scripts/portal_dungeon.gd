extends Area2D

@export var next_scene: String = "res://Levels/Scenes/main_dungeon.tscn"

var loading_screen_scene = preload("res://UI/ui_scenes/loading_screen.tscn")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		var loading_screen = loading_screen_scene.instantiate()
		get_tree().root.add_child(loading_screen)
		loading_screen.load_scene(next_scene)
