extends Node2D

const SPEED      = 300.0
var direction    = 1.0    # 1 = right, -1 = left
var has_hit      = false

@onready var sprite = $AnimatedSprite2D

func _ready():
	sprite.play("idle")
	# rotate sprite 90 degrees since it faces down
	sprite.rotation_degrees = 90 if direction > 0 else -90

func launch(dir: float, spawn_pos: Vector2):
	direction        = dir
	global_position  = spawn_pos
	sprite.rotation_degrees = 90 if direction > 0 else -90

func _physics_process(delta):
	if has_hit:
		return
	position.x += direction * SPEED * delta

	# despawn after travelling far enough
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist > 600.0:
			queue_free()

func _on_body_entered(body):
	if has_hit:
		return
	if body.is_in_group("player"):
		has_hit = true
		if body.has_method("take_damage"):
			body.take_damage()
		queue_free()
