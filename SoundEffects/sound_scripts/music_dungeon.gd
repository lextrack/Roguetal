extends AudioStreamPlayer2D

# Ya no necesitas declarar 'level_music' porque usarás la propiedad 'stream' que viene por defecto

func _play_music(volume = 0.0):
	# Asegúrate de que haya un audio en 'stream'
	if stream == null:
		return
	
	volume_db = volume
	play()
	
func play_music_level():
	_play_music()

func stop_music():
	stop()  # Detiene la música
