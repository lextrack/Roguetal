extends Node

class_name player_data

static var health: float = 4.0
static var ammo: int = 100
static var kill_count: int = 0
static var time_played: float = 0.0
static var highest_kill_streak: int = 0
static var current_kill_streak: int = 0

static func reset_stats():
	health = 4.0
	ammo = 100
	kill_count = 0
	time_played = 0.0
	highest_kill_streak = 0
	current_kill_streak = 0

static func update_kill_streak():
	current_kill_streak += 1
	if current_kill_streak > highest_kill_streak:
		highest_kill_streak = current_kill_streak

static func reset_kill_streak():
	current_kill_streak = 0
