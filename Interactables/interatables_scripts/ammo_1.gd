extends Area2D

@export var ammo = 10

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_data.ammo += ammo
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()
