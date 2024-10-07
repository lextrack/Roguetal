extends Node2D

func _ready() -> void:
	$animation_impact.play("Active")
	await get_tree().create_timer(0.4).timeout
	queue_free()
