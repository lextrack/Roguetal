extends Area2D

@onready var portal_enter_sound: AudioStreamPlayer2D = $portal_enter_sound

func _ready() -> void:
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		portal_enter_sound.play()
		await portal_enter_sound.finished
		
		var loading_screen = preload("res://UI/ui_scenes/loading_screen.tscn").instantiate()
		get_tree().current_scene.add_child(loading_screen)

		loading_screen.load_scene("res://Levels/Scenes/main_world.tscn")
