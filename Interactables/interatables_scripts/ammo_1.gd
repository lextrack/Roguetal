extends Area2D

@export var ammo = 10
@onready var pickup_ammo: AudioStreamPlayer2D = $pickup_ammo


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		pickup_ammo.play()
		await pickup_ammo.finished
		player_data.ammo += ammo
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()
