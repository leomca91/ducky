extends Node2D

const SPEED          = 60.0
const DEPTH_SPEED    = 40.0
const FLOOR_TOP      = 300.0
const FLOOR_BOTTOM   = 415.0
const ATTACK_RANGE   = 15.0
const ATTACK_DAMAGE  = 8
const ATTACK_RATE    = 1.5
const MAX_HEALTH     = 60

var health           = MAX_HEALTH
var player           = null
var attack_timer     = 0.0
var is_dead          = false
var is_attacking     = false
var flash_timer      = 0.0
var flash_color      = Color(1, 1, 1, 1)
var is_flashing      = false

@onready var sprite  = $AnimatedSprite2D

# shader that tints the whole sprite a solid colour
const FLASH_SHADER = """
shader_type canvas_item;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a > 0.0) {
		COLOR = mix(tex, vec4(flash_color.rgb, tex.a), flash_color.a);
	} else {
		COLOR = tex;
	}
}
"""

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	position.y = FLOOR_BOTTOM
	sprite.animation_finished.connect(_on_animation_finished)

	# apply shader to sprite
	var shader        = Shader.new()
	shader.code       = FLASH_SHADER
	var mat           = ShaderMaterial.new()
	mat.shader        = shader
	sprite.material   = mat

func _on_animation_finished():
	if sprite.animation == "attack":
		is_attacking = false
		sprite.play("idle")

func _physics_process(delta):
	if is_dead or player == null:
		return

	# tick flash
	if is_flashing:
		flash_timer -= delta
		# pulse the flash alpha
		var alpha = clamp(flash_timer / 0.15, 0.0, 1.0)
		(sprite.material as ShaderMaterial).set_shader_parameter(
			"flash_color", Color(flash_color.r, flash_color.g, flash_color.b, alpha)
		)
		if flash_timer <= 0.0:
			is_flashing = false
			(sprite.material as ShaderMaterial).set_shader_parameter(
				"flash_color", Color(1, 1, 1, 0)
			)

	attack_timer -= delta

	var dist = global_position.distance_to(player.global_position)

	if dist <= ATTACK_RANGE:
		if attack_timer <= 0.0:
			_do_attack()
	else:
		_move_toward_player(delta)

	var t  = (position.y - FLOOR_TOP) / (FLOOR_BOTTOM - FLOOR_TOP)
	var sc = lerp(0.7, 1.0, t)
	scale  = Vector2(sc, sc)

func _move_toward_player(delta):
	var dir = (player.global_position - global_position).normalized()

	position.x += dir.x * SPEED * delta

	var depth_diff = player.position.y - position.y
	if abs(depth_diff) > 2.0:
		position.y += sign(depth_diff) * DEPTH_SPEED * delta
		position.y  = clamp(position.y, FLOOR_TOP, FLOOR_BOTTOM)

	sprite.flip_h = dir.x < 0
	sprite.play("walk")

func _do_attack():
	attack_timer = ATTACK_RATE
	is_attacking = true
	sprite.play("attack")
	if player and player.has_method("take_damage"):
		player.take_damage()

func _flash(color: Color):
	flash_color = color
	flash_timer = 0.15
	is_flashing = true
	(sprite.material as ShaderMaterial).set_shader_parameter(
		"flash_color", Color(color.r, color.g, color.b, 1.0)
	)

func take_damage(amount: int, from_pos: Vector2):
	if is_dead:
		return
	health -= amount

	# white flash on hurt
	_flash(Color(1, 1, 1))

	var knockback = (global_position - from_pos).normalized() * 30.0
	position     += knockback

	if health <= 0:
		_die()

func _die():
	is_dead = true
	# red flash then fade out and disappear
	_flash(Color(1, 0, 0))
	_death_sequence()

func _death_sequence():
	# flash red several times then fade out
	var tween = create_tween()
	for i in range(4):
		tween.tween_callback(_flash.bind(Color(1, 0, 0)))
		tween.tween_interval(0.1)
		tween.tween_callback(_clear_flash)
		tween.tween_interval(0.1)
	# fade sprite out
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _clear_flash():
	(sprite.material as ShaderMaterial).set_shader_parameter(
		"flash_color", Color(1, 1, 1, 0)
	)
