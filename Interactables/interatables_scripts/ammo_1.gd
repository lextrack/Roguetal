extends Area2D

@export var ammo = 20
@export var attraction_speed = 200

@onready var pickup_ammo: AudioStreamPlayer2D = $pickup_ammo

var being_attracted = false
var player: WeakRef = null  # Usamos WeakRef para evitar referencias fuertes

func _ready() -> void:
	add_to_group("ammo")

func _process(delta: float) -> void:
	if being_attracted and player and player.get_ref():
		var player_node = player.get_ref()
		if is_instance_valid(player_node):
			var direction = (player_node.global_position - global_position).normalized()
			global_position += direction * attraction_speed * delta
		else:
			stop_attraction()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not body.is_dead:
		pickup_ammo.play()
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(self) and is_instance_valid(body):
			player_data.ammo += ammo
			queue_free()

func _on_timer_timeout() -> void:
	queue_free()

func start_attraction(target_player):
	being_attracted = true
	player = weakref(target_player)

func stop_attraction():
	being_attracted = false
	player = null

func _exit_tree() -> void:
	stop_attraction()
