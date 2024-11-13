extends Node
class_name EnemyScalingManager

# Difficulty tracking per level
var level_difficulty = {
	"res://Levels/Scenes/main_dungeon.tscn": 0,
	"res://Levels/Scenes/main_dungeon_2.tscn": 0,
	"res://Levels/Scenes/labyrinth_level.tscn": 0
}

# Base values
var base_normal_enemies: int = 6
var base_shooter_enemies: int = 3

# Scaling configuration
var scaling_factor: float = 0.20
var max_normal_enemies: int = 32
var max_shooter_enemies: int = 18
var min_increase: int = 2

func increment_difficulty(level_path: String) -> void:
	if level_path in level_difficulty:
		level_difficulty[level_path] += 1
		print("Difficulty for %s increased to %d" % [level_path.get_file(), level_difficulty[level_path]])

func register_player_death(level_path: String) -> void:
	if level_path in level_difficulty:
		print("Player died in %s, resetting all difficulties to 0" % level_path.get_file())
		reset()

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
