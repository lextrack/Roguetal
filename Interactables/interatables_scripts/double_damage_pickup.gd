extends Area2D

@onready var pickup_object: AudioStreamPlayer2D = $pickup_object

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_body_entered(body):
	if body.name == "Player" and body.has_node("PowerUpManager"):
		pickup_object.play()
		await pickup_object.finished
		body.get_node("PowerUpManager").activate_double_damage()
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	pass
