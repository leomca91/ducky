extends Node2D

const SPEED              = 300.0
const DEPTH_SPEED        = 20.0
const FLOOR_TOP          = 300.0
const FLOOR_BOTTOM       = 415.0
const ATTACK_RANGE       = 200.0
const ATTACK_RATE        = 2.5
const ATTACK_WARN        = 0.5
const MAX_HEALTH         = 90
const WEIGHT             = 8.0
const MIN_DISTANCE       = 80.0
const PROJECTILE_SCENE   = "res://Scenes/crab_projectile.tscn"

var health            = MAX_HEALTH
var player            = null
var attack_timer      = 0.0
var is_dead           = false
var is_attacking      = false
var is_warning        = false
var is_active         = false
var warn_timer        = 0.0
var attack_anim_timer = 0.0
var flash_timer       = 0.0
var flash_color       = Color(1, 1, 1, 1)
var is_flashing       = false

@onready var sprite   = $AnimatedSprite2D
@onready var notifier = $VisibleOnScreenNotifier2D

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
	position.y    = FLOOR_BOTTOM
	sprite.flip_h = true    # sprite faces right by default so flip to face left
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("Idle")
	notifier.screen_entered.connect(_on_screen_entered)

	var shader      = Shader.new()
	shader.code     = FLASH_SHADER
	var mat         = ShaderMaterial.new()
	mat.shader      = shader
	sprite.material = mat

func _on_screen_entered():
	is_active = true

func _on_animation_finished():
	if sprite.animation == "Attack":
		is_attacking      = false
		attack_anim_timer = 0.0
		sprite.play("Idle")

func _physics_process(delta):
	if is_dead or player == null:
		return

	if not is_active:
		sprite.play("Idle")
		return

	if is_flashing:
		flash_timer -= delta
		var alpha = clamp(flash_timer / 0.15, 0.0, 1.0)
		(sprite.material as ShaderMaterial).set_shader_parameter(
			"flash_color", Color(flash_color.r, flash_color.g, flash_color.b, alpha)
		)
		if flash_timer <= 0.0:
			is_flashing = false
			_clear_flash()

	if is_warning:
		warn_timer -= delta
		var pulse = abs(sin(warn_timer * 20.0))
		(sprite.material as ShaderMaterial).set_shader_parameter(
			"flash_color", Color(0.2, 0.4, 1.0, pulse * 0.8)
		)
		if warn_timer <= 0.0:
			is_warning = false
			_clear_flash()
			_execute_attack()

	if is_attacking:
		attack_anim_timer += delta
		if attack_anim_timer > 3.0:
			is_attacking      = false
			attack_anim_timer = 0.0

	attack_timer -= delta

	var hdist = abs(global_position.x - player.global_position.x)

	if hdist <= ATTACK_RANGE:
		if attack_timer <= 0.0 and not is_attacking and not is_warning:
			_start_warning()
		_move_depth(delta)
	else:
		_move_toward_player(delta)

	var t  = (position.y - FLOOR_TOP) / (FLOOR_BOTTOM - FLOOR_TOP)
	var sc = lerp(0.7, 1.0, t)
	scale  = Vector2(sc, sc)

func _move_toward_player(delta):
	if is_attacking or is_warning:
		return
	var dir = (player.global_position - global_position).normalized()
	position.x    += dir.x * SPEED * delta
	# flip_h true = facing left, false = facing right
	sprite.flip_h  = dir.x > 0
	sprite.play("Idle")
	_move_depth(delta)

func _move_depth(delta):
	var depth_diff = player.position.y - position.y
	if abs(depth_diff) > 2.0:
		position.y += sign(depth_diff) * DEPTH_SPEED * delta
		position.y  = clamp(position.y, FLOOR_TOP, FLOOR_BOTTOM)

func _start_warning():
	is_warning = true
	warn_timer  = ATTACK_WARN
	sprite.play("Idle")

func _execute_attack():
	attack_timer      = ATTACK_RATE
	is_attacking      = true
	attack_anim_timer = 0.0
	sprite.play("Attack")
	await get_tree().create_timer(0.2).timeout
	if is_dead:
		return
	_spawn_projectile()

func _spawn_projectile():
	var proj_scene = load(PROJECTILE_SCENE)
	if proj_scene == null:
		print("Could not load projectile scene at: ", PROJECTILE_SCENE)
		return
	var proj = proj_scene.instantiate()
	get_parent().add_child(proj)
	var dir = sign(player.global_position.x - global_position.x)
	proj.launch(dir, global_position)

func _flash(color: Color):
	flash_color = color
	flash_timer = 0.15
	is_flashing = true
	(sprite.material as ShaderMaterial).set_shader_parameter(
		"flash_color", Color(color.r, color.g, color.b, 1.0)
	)

func take_damage(amount: int, from_pos: Vector2, attack_type: String = "jab"):
	if is_dead:
		return
	health -= amount
	_flash(Color(1, 1, 1))
	is_active = true

	var knockback = _calculate_knockback(amount, attack_type)
	var dir_x     = sign(global_position.x - from_pos.x)
	position.x   += dir_x * knockback
	position.y    = clamp(position.y, FLOOR_TOP, FLOOR_BOTTOM)

	if is_warning:
		is_warning = false
		warn_timer = 0.0
		_clear_flash()

	if health <= 0:
		_die()

func _calculate_knockback(amount: int, attack_type: String) -> float:
	var weight_factor = 1.0 - ((WEIGHT - 1.0) / 9.0)
	match attack_type:
		"jab":    return 3.0
		"spam":   return 2.0
		"smash":
			var base = 80.0 + amount * 3.0
			return base * weight_factor
		"usmash": return 20.0 * weight_factor
		_:        return 5.0

func _die():
	is_dead = true
	_death_sequence()

func _death_sequence():
	var tween = create_tween()
	for i in range(4):
		tween.tween_callback(_flash.bind(Color(1, 0, 0)))
		tween.tween_interval(0.1)
		tween.tween_callback(_clear_flash)
		tween.tween_interval(0.1)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _clear_flash():
	(sprite.material as ShaderMaterial).set_shader_parameter(
		"flash_color", Color(1, 1, 1, 0)
	)
