extends Node2D

@onready var dungeon_portal = preload("res://Interactables/Scenes/portal_dungeon.tscn")

func _ready() -> void:
	MusicManager.play_main_level_music()
