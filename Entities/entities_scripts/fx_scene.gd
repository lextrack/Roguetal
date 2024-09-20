extends Node2D

func _ready() -> void:
	$anim.play("Active")
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _process(delta: float) -> void:
	pass
