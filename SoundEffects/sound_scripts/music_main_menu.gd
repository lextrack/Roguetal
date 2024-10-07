extends AudioStreamPlayer2D

func _play_music(volume = 8.0):
	if stream == null:
		return
	
	volume_db = volume
	play()
	
func play_music_level():
	_play_music()

func stop_music():
	stop()
