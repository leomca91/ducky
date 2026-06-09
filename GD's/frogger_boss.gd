extends CharacterBody2D

const FLOOR_TOP          = 250.0    # wider than normal level
const FLOOR_BOTTOM       = 450.0
const BASE_SPEED         = 112.0    # 0.75x player speed (150 * 0.75)
const ATTACK_RATE        = 2.0
const TONGUE_RANGE       = 80.0
const SPIT_RANGE         = 250.0
const SPIT_MIN_RANGE     = 90.0     # wont spit if too close
const MAX_HEALTH         = 300
const HEAL_THRESHOLD_1   = 0.33     # heals at 33%
const HEAL_THRESHOLD_2   = 0.20     # heals at 20%
const HEAL_THRESHOLD_3   = 0.10     # heals at 10%
const SPEED_BOOST        = 1.15     # 15% faster per heal
const DEPTH_SPEED        = 50.0
const SPIT_SCENE         = "res://Scenes/frog_spit.tscn"

var health               = MAX_HEALTH
var speed                = BASE_SPEED
var player               = null
var attack_timer         = 0.0
var is_dead              = false
var is_attacking         = false
var is_healing           = false
var heal_count           = 0        # how many times healed
var has_healed_1         = false
var has_healed_2         = false
var has_healed_3         = false
var attack_anim_timer    = 0.0
var flash_timer          = 0.0
var flash_color          = Color(1, 1, 1, 1)
var is_flashing          = false
var boss_hud             = null

@onready var sprite      = $AnimatedSprite2D

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
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("Idle")
	position.y = FLOOR_BOTTOM

	var shader      = Shader.new()
	shader.code     = FLASH_SHADER
	var mat         = ShaderMaterial.new()
	mat.shader      = shader
	sprite.material = mat

	await get_tree().process_frame
	player   = get_tree().get_first_node_in_group("player")
	boss_hud = get_tree().get_first_node_in_group("boss_hud")
	if boss_hud:
		boss_hud.set_max_health(MAX_HEALTH)

func _on_animation_finished():
	match sprite.animation:
		"Tongue", "Spit":
			is_attacking      = false
			attack_anim_timer = 0.0
			sprite.play("Idle")
		"Hurt":
			sprite.play("Idle")
		"Heal":
			is_healing = false
			sprite.play("Idle")

func _physics_process(delta):
	if is_dead or player == null or is_healing:
		return

	# flash handling
	if is_flashing:
		flash_timer -= delta
		var alpha = clamp(flash_timer / 0.15, 0.0, 1.0)
		(sprite.material as ShaderMaterial).set_shader_parameter(
			"flash_color", Color(flash_color.r, flash_color.g, flash_color.b, alpha)
		)
		if flash_timer <= 0.0:
			is_flashing = false
			_clear_flash()

	attack_timer -= delta

	var hdist      = abs(global_position.x - player.global_position.x)
	var depth_diff = player.position.y - position.y

	# check heal thresholds
	_check_heal()

	if not is_attacking:
		_move_toward_player(delta, hdist, depth_diff)

		if attack_timer <= 0.0:
			if hdist <= TONGUE_RANGE:
				_do_tongue()
			elif hdist <= SPIT_RANGE and hdist > SPIT_MIN_RANGE:
				_do_spit()

	# failsafe
	if is_attacking:
		attack_anim_timer += delta
		if attack_anim_timer > 3.0:
			is_attacking      = false
			attack_anim_timer = 0.0

	velocity.y = 0
	move_and_slide()

	# depth movement
	position.y = clamp(position.y, FLOOR_TOP, FLOOR_BOTTOM)

	# perspective scale
	var t  = (position.y - FLOOR_TOP) / (FLOOR_BOTTOM - FLOOR_TOP)
	var sc = lerp(0.8, 1.2, t)
	scale  = Vector2(sc, sc)

func _move_toward_player(delta, hdist, depth_diff):
	var dir = sign(player.global_position.x - global_position.x)
	# keep some distance for spit attacks
	if hdist > TONGUE_RANGE:
		velocity.x     = dir * speed
		sprite.flip_h  = dir < 0
	else:
		velocity.x = 0

	sprite.play("Move" if velocity.x != 0 else "Idle")

	# depth movement
	if abs(depth_diff) > 2.0:
		position.y += sign(depth_diff) * DEPTH_SPEED * delta

func _check_heal():
	var pct = float(health) / float(MAX_HEALTH)
	if not has_healed_1 and pct <= HEAL_THRESHOLD_1:
		has_healed_1 = true
		_do_heal()
	elif not has_healed_2 and has_healed_1 and pct <= HEAL_THRESHOLD_2:
		has_healed_2 = true
		_do_heal()
	elif not has_healed_3 and has_healed_2 and pct <= HEAL_THRESHOLD_3:
		has_healed_3 = true
		_do_heal()

func _do_heal():
	is_healing   = true
	is_attacking = false
	velocity.x   = 0
	sprite.play("Heal")
	heal_count  += 1
	speed        = BASE_SPEED * pow(SPEED_BOOST, heal_count)
	health       = MAX_HEALTH
	if boss_hud:
		boss_hud.heal_to_full()

func _do_tongue():
	is_attacking      = true
	attack_anim_timer = 0.0
	attack_timer      = ATTACK_RATE
	sprite.play("Tongue")
	# damage player after short delay — tongue takes time to extend
	await get_tree().create_timer(0.3).timeout
	if is_dead:
		return
	var hdist = abs(global_position.x - player.global_position.x)
	var ddist = abs(position.y - player.position.y)
	if hdist <= TONGUE_RANGE and ddist < 30.0 and player.visual_offset > -20.0:
		var dir = sign(player.global_position.x - global_position.x)
		player.take_damage(dir)

func _do_spit():
	is_attacking      = true
	attack_anim_timer = 0.0
	attack_timer      = ATTACK_RATE
	sprite.play("Spit")
	await get_tree().create_timer(0.4).timeout
	if is_dead:
		return
	_spawn_spit()

func _spawn_spit():
	var spit_scene = load(SPIT_SCENE)
	if spit_scene == null:
		print("Could not load spit scene: ", SPIT_SCENE)
		return
	var spit = spit_scene.instantiate()
	get_parent().add_child(spit)
	var dir = sign(player.global_position.x - global_position.x)
	spit.launch(dir, global_position)

func _flash(color: Color):
	flash_color = color
	flash_timer = 0.15
	is_flashing = true
	(sprite.material as ShaderMaterial).set_shader_parameter(
		"flash_color", Color(color.r, color.g, color.b, 1.0)
	)

func take_damage(amount: int, from_pos: Vector2, attack_type: String = "jab"):
	if is_dead or is_healing:
		return
	health -= amount
	_flash(Color(1, 1, 1))
	sprite.play("Hurt")

	# knockback
	var dir_x   = sign(global_position.x - from_pos.x)
	position.x += dir_x * 20.0

	if boss_hud:
		boss_hud.take_damage(amount)

	if health <= 0 and has_healed_3:
		_die()
	elif health <= 0:
		health = 1    # cant die before all heals used

func _die():
	is_dead    = true
	velocity.x = 0
	sprite.play("Hurt")
	await get_tree().create_timer(1.0).timeout
	# go back to main level or show win screen
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _clear_flash():
	(sprite.material as ShaderMaterial).set_shader_parameter(
		"flash_color", Color(1, 1, 1, 0)
	)
