extends Area2D

@onready var fx_scene = preload("res://Entities/Scenes/FX/fx_missile_effect.tscn")
@export var speed = 110
@export var damage = 1
@export var explosion_radius = 100
@export var explosion_falloff = true

var direction = Vector2.RIGHT

func _ready() -> void:
	rotation = direction.angle()

func _process(delta: float) -> void:
	translate(direction * speed * delta)

func _on_body_entered(body: Node2D) -> void:
	impact(body)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		impact(area)

func impact(body: Node2D):
	Globals.camera.screen_shake(1, 0.6, 0.05)
	$CollisionShape2D.call_deferred("set_disabled", true)
	set_physics_process(false)
	
	var impact_node = Node2D.new()
	impact_node.global_position = global_position
	var impact_sound = AudioStreamPlayer.new()
	impact_sound.stream = $AudioStreamImpactBazooka.stream
	impact_node.add_child(impact_sound)
	get_tree().root.add_child(impact_node)
	impact_sound.play()
	
	instance_fx()
	
	create_explosion()
	
	queue_free()
	await get_tree().create_timer(impact_sound.stream.get_length()).timeout
	impact_node.queue_free()

func create_explosion():
	var space_state = get_world_2d().direct_space_state
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= explosion_radius:
			var query = PhysicsRayQueryParameters2D.create(global_position, enemy.global_position)
			query.collision_mask = 0b00000000000000000001
			var result = space_state.intersect_ray(query)
			
			if result.is_empty() or result["collider"] == enemy:
				var explosion_damage = damage
				if explosion_falloff:
					var damage_multiplier = 1 - (distance / explosion_radius)
					explosion_damage *= damage_multiplier
				enemy.take_damage(explosion_damage, self)
			
func _on_visible_screen_exited() -> void:
	queue_free()

func instance_fx():
	var fx = fx_scene.instantiate()
	fx.global_position = global_position
	fx.scale = Vector2(explosion_radius / 70, explosion_radius / 70)
	get_tree().root.add_child(fx)
