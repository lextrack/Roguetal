extends Area2D

@onready var pickup_object: AudioStreamPlayer2D = $pickup_object

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("activate_double_speed"):
		pickup_object.play()
		await pickup_object.finished
		body.activate_double_speed()
		queue_free()
