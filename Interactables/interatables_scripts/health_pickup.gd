extends Area2D

@export var health_increase = 4
@onready var pickup_object: AudioStreamPlayer2D = $pickup_object

func _ready() -> void:
	$heart_collider.set_deferred("disabled", false)

func _on_area_entered(area: Area2D) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		pickup_object.play()
		await pickup_object.finished
		body.increase_health(health_increase) 
		queue_free()
