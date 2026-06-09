extends Area2D

const SPEED   = 250.0
var direction = 1.0
var has_hit   = false

@onready var sprite = $AnimatedSprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	# play whatever your spit animation is called
	if sprite.sprite_frames.has_animation("Spit"):
		sprite.play("Spit")

func launch(dir: float, spawn_pos: Vector2):
	direction       = dir
	global_position = spawn_pos
	sprite.flip_h   = dir < 0

func _physics_process(delta):
	if has_hit:
		return
	position.x += direction * SPEED * delta
	# despawn if too far
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) > 800.0:
		queue_free()

func _on_body_entered(body):
	if has_hit:
		return
	if body.is_in_group("player"):
		has_hit = true
		body.take_damage(direction)
		queue_free()
