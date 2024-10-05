extends Area2D

@export var ammo = 10
@export var attraction_speed = 200

@onready var pickup_ammo: AudioStreamPlayer2D = $pickup_ammo

var being_attracted = false
var player: Node2D = null

func _ready() -> void:
	add_to_group("ammo")

func _process(delta: float) -> void:
	if being_attracted and player:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * attraction_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		pickup_ammo.play()
		await get_tree().create_timer(0.2).timeout
		player_data.ammo += ammo
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()

func start_attraction(target_player):
	being_attracted = true
	player = target_player
