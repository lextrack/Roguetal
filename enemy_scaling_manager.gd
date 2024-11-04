extends Node

class_name EnemyScalingManager

# Difficulty tracking per level
var level_difficulty = {
	"res://Levels/Scenes/main_dungeon.tscn": 0,
	"res://Levels/Scenes/main_dungeon_2.tscn": 0,
	"res://Levels/Scenes/labyrinth_level.tscn": 0
}

var last_death_level = ""

# Base values
var base_normal_enemies: int = 8
var base_shooter_enemies: int = 5

# Scaling configuration
var scaling_factor: float = 0.20
var max_normal_enemies: int = 25
var max_shooter_enemies: int = 15
var min_increase: int = 2

func increment_difficulty(level_path: String) -> void:
	if level_path in level_difficulty:
		if level_path != last_death_level:
			level_difficulty[level_path] += 1
			print("Difficulty for %s increased to %d" % [level_path.get_file(), level_difficulty[level_path]])
		else:
			print("Maintaining difficulty for %s at %d (player died)" % [
				level_path.get_file(), 
				level_difficulty[level_path]
			])
			last_death_level = ""

func register_player_death(level_path: String) -> void:
	if level_path in level_difficulty:
		last_death_level = level_path
		print("Registered player death in %s" % level_path.get_file())

func get_enemy_counts(level_path: String) -> Dictionary:
	var difficulty = level_difficulty.get(level_path, 0)
	
	var normal_increase = max(
		min_increase,
		floor(base_normal_enemies * scaling_factor * difficulty)
	)
	var shooter_increase = max(
		min_increase,
		floor(base_shooter_enemies * scaling_factor * difficulty)
	)
	
	var normal_enemies = min(
		base_normal_enemies + normal_increase,
		max_normal_enemies
	)
	var shooter_enemies = min(
		base_shooter_enemies + shooter_increase,
		max_shooter_enemies
	)
	
	print("Enemy counts for %s:" % level_path.get_file())
	print("- Normal enemies: %d (base) + %d (increase) = %d" % [
		base_normal_enemies,
		normal_increase,
		normal_enemies
	])
	print("- Shooter enemies: %d (base) + %d (increase) = %d" % [
		base_shooter_enemies,
		shooter_increase,
		shooter_enemies
	])
	
	return {
		"normal_enemies": normal_enemies,
		"shooter_enemies": shooter_enemies
	}

func reset() -> void:
	for key in level_difficulty.keys():
		level_difficulty[key] = 0
	last_death_level = ""
