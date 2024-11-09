extends AudioStreamPlayer2D

var is_playing_level_music = false

func play_music(volume = -5.0):
	if stream == null:
		return
	
	volume_db = volume
	if not playing:
		play()

func play_music_level():
	if not is_playing_level_music:
		is_playing_level_music = true
		play_music()

func stop_music():
	stop()
	is_playing_level_music = false
