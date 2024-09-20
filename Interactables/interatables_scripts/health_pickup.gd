extends Area2D

@export var health_increase = 4

func _ready() -> void:
	$heart_collider.set_deferred("disabled", false)


func _process(delta: float) -> void:
	pass


func _on_area_entered(area: Area2D) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.increase_health(health_increase) 
		queue_free()
