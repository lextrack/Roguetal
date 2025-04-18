extends Node

const SAVE_FILE = "user://game_stats.save"

var stats = {
	"total_kills": 0,
	"total_time_played": 0.0,
	"highest_streak_ever": 0,
	"games_played": 0,
	"average_time_per_game": 0.0,
	"average_kills_per_game": 0.0
}

func _ready():
	load_stats()

func save_stats():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var(stats)

func load_stats():
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			stats = file.get_var()

func update_session_stats():
	stats.total_kills += player_data.kill_count
	stats.total_time_played += player_data.time_played
	
	if player_data.highest_kill_streak > stats.highest_streak_ever:
		stats.highest_streak_ever = player_data.highest_kill_streak
	
	stats.games_played += 1
	stats.average_time_per_game = stats.total_time_played / stats.games_played
	stats.average_kills_per_game = float(stats.total_kills) / stats.games_played
	
	save_stats()

func get_formatted_stats() -> Dictionary:
	return {
		"total_kills": str(stats.total_kills),
		"total_time": format_time(stats.total_time_played),
		"highest_streak": str(stats.highest_streak_ever),
		"games_played": str(stats.games_played),
		"avg_time": format_time(stats.average_time_per_game),
		"avg_kills": "%.2f" % stats.average_kills_per_game
	}

func format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var secs = total_seconds % 60
	
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	else:
		return "%02d:%02d" % [minutes, secs]
