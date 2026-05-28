extends Area2D

const SPEED   = 300.0
var direction = 1.0
var has_hit   = false

@onready var sprite = $AnimatedSprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	sprite.play("CrabProjectile")

func launch(dir: float, spawn_pos: Vector2):
	direction       = dir
	global_position = spawn_pos
	# projectile faces down so rotate to go horizontal
	# -90 = faces right, 90 = faces left
	sprite.rotation_degrees = -90 if direction > 0 else 90

func _physics_process(delta):
	if has_hit:
		return
	position.x += direction * SPEED * delta
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if global_position.distance_to(player.global_position) > 600.0:
			queue_free()

func _on_body_entered(body):
	if has_hit:
		return
	if body.is_in_group("player"):
		has_hit = true
		body.take_damage()
		queue_free()
