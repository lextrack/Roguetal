extends Node

class_name EnemyGroupBehavior

var enemies = []
var group_center = Vector2.ZERO
var spread_factor = 50.0  # Ajusta este valor para cambiar qué tan separados se mantienen los enemigos

func _init():
	add_to_group("enemy_group_behavior")

func _ready():
	# Asegurarse de que este nodo no se destruya automáticamente
	set_process_mode(Node.PROCESS_MODE_ALWAYS)

func add_enemy(enemy):
	if enemy not in enemies:
		enemies.append(enemy)

func remove_enemy(enemy):
	enemies.erase(enemy)

func update_group_behavior(target_position):
	if enemies.is_empty():
		return
	
	group_center = Vector2.ZERO
	for enemy in enemies:
		if is_instance_valid(enemy):
			group_center += enemy.global_position
		else:
			enemies.erase(enemy)
	
	if enemies.is_empty():
		return
	
	group_center /= enemies.size()

	for enemy in enemies:
		if is_instance_valid(enemy):
			var offset = calculate_offset(enemy, target_position)
			enemy.update_chase_position(target_position + offset)

func calculate_offset(enemy, target_position):
	var to_center = group_center - enemy.global_position
	var to_target = target_position - enemy.global_position
	var perpendicular = to_target.rotated(PI/2).normalized()
	
	var offset = perpendicular * spread_factor * randf_range(0.5, 1.5)
	offset += to_center.normalized() * spread_factor * 0.5
	
	return offset

# Llamar a esta función en el _process o _physics_process del script principal
func process_group_behavior(target_position):
	update_group_behavior(target_position)
