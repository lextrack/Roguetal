extends Area2D

@onready var fx_scene = preload("res://Entities/Scenes/FX/fx_scene.tscn")
@export var speed = 100
@export var damage = 1
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
	Globals.camera.screen_shake(1, 0.5, 0.04)

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
	
	if body.is_in_group("enemy"):
		body.take_damage(damage, self)  # Pasa la referencia de la bala

	queue_free()  # Asegúrate de que esto se ejecute después de hacer el daño

	await get_tree().create_timer(impact_sound.stream.get_length()).timeout
	impact_node.queue_free()

func _on_visible_screen_exited() -> void:
	queue_free()

func instance_fx():
	var fx = fx_scene.instantiate()
	fx.global_position = global_position
	get_tree().root.add_child(fx)
