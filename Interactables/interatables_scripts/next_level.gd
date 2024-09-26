extends Area2D

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	randomize()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		var levels = ["res://Levels/Scenes/main_dungeon.tscn", "res://Levels/Scenes/main_dungeon_2.tscn"]
		var random_level = levels[randi() % levels.size()]
		get_tree().call_deferred("change_scene_to_file", random_level)
