extends Node

var music_tracks = []
var current_music = null
var music_volume = 1.0
var main_level_music = null
var main_menu_music = null 

func _ready():
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus(-1)
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "Music")
	
	music_tracks = [
		MusicDungeon,
		MusicDungeon2,
		MusicDungeon3,
		MusicDungeon4
	]
	
	main_level_music = MusicMainLevel
	main_level_music.bus = "Music"
	
	main_menu_music = MusicMainMenu
	main_menu_music.bus = "Music"
	
	for track in music_tracks:
		track.finished.connect(_on_music_finished.bind(track))
		track.bus = "Music"
		
	set_music_volume(music_volume)

func _on_music_finished(music_that_finished):
	var available_tracks = music_tracks.duplicate()
	available_tracks.erase(music_that_finished)
	
	var next_track = available_tracks[randi() % available_tracks.size()]
	
	music_that_finished.stop_music()
	next_track.play_music_level()
	current_music = next_track

func set_music_volume(value: float):
	music_volume = value
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)

func get_music_volume() -> float:
	return music_volume

func play_main_level_music():
	stop_all_music()
	if main_level_music:
		main_level_music.play_music_level()
		
func play_main_menu_music():
	stop_all_music()
	if main_menu_music:
		main_menu_music.play_music_level()

func ensure_music_playing():
	var is_any_playing = false
	for track in music_tracks:
		if track.is_playing_level_music:
			is_any_playing = true
			break
	
	if not is_any_playing:
		stop_all_music()
		var random_track = music_tracks[randi() % music_tracks.size()]
		random_track.play_music_level()
		current_music = random_track

func stop_all_music():
	for track in music_tracks:
		track.stop_music()
	if main_level_music:
		main_level_music.stop_music()
	if main_menu_music:
		main_menu_music.stop_music()
	current_music = null
	
