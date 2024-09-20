extends Node2D

@onready var dungeon_portal = preload("res://Interactables/Scenes/portal_dungeon.tscn")
@onready var background_music_player = $BackgroundMusicPlayerMainWorld 

func _ready() -> void:
	instance_portal_dungeon()
	background_music_player.play()
	MusicDungeon.stop_music()

func instance_portal_dungeon():
	var portaldungeon = dungeon_portal.instantiate()
	add_child(portaldungeon)
	portaldungeon.position = Vector2(50, 46)

func _process(delta: float) -> void:
	pass
