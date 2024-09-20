extends Node2D

@onready var dungeon_portal = preload("res://Interactables/Scenes/portal_dungeon.tscn")

func _ready() -> void:
	MusicDungeon.stop_music()
	MusicMainLevel.play_music_level()

func _process(delta: float) -> void:
	pass
