extends Node2D

func _ready() -> void:
	$animation_bazooka.play("Active")
	await get_tree().create_timer(0.4).timeout
	queue_free()

func _process(delta: float) -> void:
	pass
