extends CharacterBody2D

const SPEED              = 150.0
const JUMP_VEL           = -300.0
const JUMP_HOLD_BOOST    = -150.0
const JUMP_HOLD_TIME     = 0.2
const GRAVITY            = 800.0
const FALL_GRAVITY       = 1100.0
const FLAP_VEL           = -220.0
const MAX_FLAPS          = 8
const DEPTH_SPEED        = 80.0
const FLOOR_TOP          = 300.0
const FLOOR_BOTTOM       = 415.0
const SPAM_HOLD_TIME     = 0.4
const CROUCH_SPEED_MULT  = 0.3
const ROLL_SPEED         = 350.0
const ROLL_DEPTH_SPEED   = 200.0
const ROLL_DURATION      = 0.35
const LEFT_BOUNDARY      = 0.0
const ATTACK_SLOW        = 0.3
const MAX_HEALTH         = 100
const PARRY_HEAL         = 15
const PARRY_WINDOW       = 0.3
const INVINCIBLE_TIME    = 0.5

const DMG_RIGHT_HOOK     = 5
const DMG_SPAM_ATTACK    = 2
const DMG_FSMASH         = 12
const DMG_FTILT          = 10
const DMG_USMASH         = 18

const REACH_RIGHT_HOOK   = 40.0
const REACH_SPAM         = 35.0
const REACH_FSMASH       = 50.0
const REACH_FTILT        = 45.0
const REACH_USMASH       = 40.0

const SPAM_HIT_RATE      = 0.15

var is_jumping           = false
var jump_y               = 0.0
var visual_offset        = 0.0
var hold_timer           = 0.0
var current_attack       = ""
var flap_count           = 0
var has_inhaled          = false
var jump_hold_timer      = 0.0
var is_holding_jump      = false
var is_crouching         = false
var is_rolling           = false
var roll_timer           = 0.0
var roll_dir_x           = 0.0
var roll_dir_y           = 0.0
var is_dead              = false
var is_hurt              = false
var invincible_timer     = 0.0
var is_parrying          = false
var parry_timer          = 0.0
var parry_used           = false
var health               = MAX_HEALTH
var hud                  = null
var spam_hit_timer       = 0.0

# attack key release flags
var q_used               = false
var e_used               = false
var r_used               = false

@onready var sprite      = $AnimatedSprite2D

func _ready():
	sprite.animation_finished.connect(_on_animation_finished)

	position.y = FLOOR_BOTTOM

	add_to_group("player")

	await get_tree().process_frame

	hud = get_tree().get_first_node_in_group("hud")

	if hud:
		hud.set_max_health(MAX_HEALTH)

func _on_animation_finished():
	match sprite.animation:

		"RightHook", "SpamAttack", "Land":
			current_attack = ""

		"Fsmash", "Ftilt", "Usmash":
			current_attack = ""

		"Inhale":
			sprite.play("Flapping")

		"Roll1":
			is_rolling = false
			current_attack = ""

		"Hurt":
			is_hurt = false

		"Parry":
			is_parrying = false
			parry_timer = 0.0

		"Death":
			pass

func _input(event):

	if is_dead:
		return

	# LEFT CLICK ATTACKS
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:

		if event.pressed:
			hold_timer = 0.0
			spam_hit_timer = 0.0
			_start_attack("RightHook")

		else:
			hold_timer = 0.0

			if current_attack == "SpamAttack":
				current_attack = ""

	# KEY PRESSES
	if event is InputEventKey and event.pressed:

		match event.keycode:

			KEY_Q:
				if not q_used:
					q_used = true
					_start_attack("Fsmash")

			KEY_E:
				if not e_used:
					e_used = true
					_start_attack("Ftilt")

			KEY_R:
				if not r_used:
					r_used = true
					_start_attack("Usmash")

			KEY_F:
				if not parry_used and not is_parrying and not is_jumping:
					is_parrying = true
					parry_timer = PARRY_WINDOW
					parry_used = true
					sprite.play("Parry")

			KEY_SHIFT:
				_do_roll()

	# KEY RELEASES
	if event is InputEventKey and not event.pressed:

		match event.keycode:

			KEY_Q:
				q_used = false

			KEY_E:
				e_used = false

			KEY_R:
				r_used = false

			KEY_F:
				parry_used = false
				is_parrying = false

func _do_roll():

	if is_rolling:
		return

	is_rolling = true
	roll_timer = ROLL_DURATION
	current_attack = "Roll1"

	var dir_x = Input.get_axis("move_left", "move_right")
	var dir_y = Input.get_axis("move_up", "move_down")

	roll_dir_x = dir_x if dir_x != 0 else (1.0 if not sprite.flip_h else -1.0)
	roll_dir_y = dir_y

	if roll_dir_x != 0:
		sprite.flip_h = roll_dir_x < 0

	sprite.play("Roll1")

func _start_attack(attack_name: String):

	if is_dead:
		return

	current_attack = attack_name
	sprite.play(attack_name)

	var damage      = 0
	var reach       = 0.0
	var attack_type = "jab"

	match attack_name:

		"RightHook":
			damage      = DMG_RIGHT_HOOK
			reach       = REACH_RIGHT_HOOK
			attack_type = "jab"

		"Fsmash":
			damage      = DMG_FSMASH
			reach       = REACH_FSMASH
			attack_type = "smash"

		"Ftilt":
			damage      = DMG_FTILT
			reach       = REACH_FTILT
			attack_type = "smash"

		"Usmash":
			damage      = DMG_USMASH
			reach       = REACH_USMASH
			attack_type = "usmash"

	if damage > 0:
		_hit_nearby_enemies(damage, reach, attack_type)

func _hit_nearby_enemies(damage: int, reach: float, attack_type: String = "jab"):

	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:

		var dist = global_position.distance_to(enemy.global_position)

		if dist < reach:
			enemy.take_damage(damage, global_position, attack_type)

func _physics_process(delta):

	if is_dead:
		return

	# INVINCIBILITY FLASH
	if invincible_timer > 0.0:

		invincible_timer -= delta

		sprite.modulate.a = 0.5 if fmod(invincible_timer, 0.1) > 0.05 else 1.0

	else:
		sprite.modulate.a = 1.0

	# PARRY TIMER
	if is_parrying and parry_timer > 0.0:
		parry_timer -= delta

	# SPAM ATTACK DAMAGE
	if current_attack == "SpamAttack":

		spam_hit_timer -= delta

		if spam_hit_timer <= 0.0:

			spam_hit_timer = SPAM_HIT_RATE

			_hit_nearby_enemies(
				DMG_SPAM_ATTACK,
				REACH_SPAM,
				"spam"
			)

	# HOLD ATTACK
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):

		hold_timer += delta

		if hold_timer >= SPAM_HOLD_TIME and current_attack != "SpamAttack":

			current_attack = "SpamAttack"
			spam_hit_timer = 0.0

			sprite.play("SpamAttack")

	else:
		hold_timer = 0.0

	# CROUCH
	is_crouching = (
		Input.is_action_pressed("crouch")
		and not is_jumping
		and not is_rolling
	)

	var attack_mult = ATTACK_SLOW if current_attack != "" else 1.0

	# ROLLING
	if is_rolling:

		roll_timer -= delta

		position.x += roll_dir_x * ROLL_SPEED * delta

		if is_jumping:

			if roll_dir_y != 0:
				visual_offset += roll_dir_y * ROLL_DEPTH_SPEED * delta

			jump_y += FALL_GRAVITY * delta * 0.8
			visual_offset += jump_y * delta

			if visual_offset >= 0.0:

				visual_offset = 0.0
				jump_y = 0.0
				is_jumping = false
				flap_count = 0
				has_inhaled = false

				sprite.play("Land")

		else:

			if roll_dir_y != 0:

				position.y += roll_dir_y * ROLL_DEPTH_SPEED * delta

				position.y = clamp(
					position.y,
					FLOOR_TOP,
					FLOOR_BOTTOM
				)

		if roll_timer <= 0.0:

			is_rolling = false
			current_attack = ""

	# NORMAL MOVEMENT
	else:

		var dir_x = Input.get_axis("move_left", "move_right")

		var spd = (
			SPEED * CROUCH_SPEED_MULT
			if is_crouching
			else SPEED * attack_mult
		)

		position.x += dir_x * spd * delta

		if dir_x != 0:
			sprite.flip_h = dir_x < 0

		if not is_jumping and not is_crouching:

			var dir_y = Input.get_axis("move_up", "move_down")

			position.y += dir_y * DEPTH_SPEED * delta

			position.y = clamp(
				position.y,
				FLOOR_TOP,
				FLOOR_BOTTOM
			)

	position.x = max(position.x, LEFT_BOUNDARY)

	# JUMPING
	if Input.is_action_just_pressed("jump") and not is_dead:

		if not is_jumping:

			is_jumping = true
			has_inhaled = false
			flap_count = 0
			jump_y = JUMP_VEL
			jump_hold_timer = 0.0
			is_holding_jump = true
			visual_offset = 0.0
			current_attack = ""

			sprite.play("Jump")

		elif flap_count < MAX_FLAPS:

			flap_count += 1
			jump_y = FLAP_VEL
			is_holding_jump = false

			if not has_inhaled:

				has_inhaled = true
				sprite.play("Inhale")

			else:
				sprite.play("Flapping")

	# HOLD JUMP
	if is_holding_jump and Input.is_action_pressed("jump"):

		jump_hold_timer += delta

		if jump_hold_timer < JUMP_HOLD_TIME:
			jump_y = lerp(jump_y, JUMP_HOLD_BOOST, 0.3)

		else:
			is_holding_jump = false

	else:
		is_holding_jump = false

	# AIR PHYSICS
	if is_jumping and not is_rolling:

		var grav = GRAVITY if jump_y < 0 else FALL_GRAVITY

		jump_y += grav * delta
		visual_offset += jump_y * delta

		if visual_offset >= 0.0:

			visual_offset = 0.0
			jump_y = 0.0
			is_jumping = false
			flap_count = 0
			has_inhaled = false

			sprite.play("Land")

	sprite.position.y = visual_offset

	# FAKE DEPTH SCALE
	var t = (
		(position.y - FLOOR_TOP)
		/ (FLOOR_BOTTOM - FLOOR_TOP)
	)

	var sc = lerp(0.7, 1.0, t)

	scale = Vector2(sc, sc)

	_update_animation()

func take_damage():

	if is_dead:
		return

	if invincible_timer > 0.0:
		return

	if is_parrying and parry_timer > 0.0:
		_successful_parry()
		return

	is_hurt = true
	invincible_timer = INVINCIBLE_TIME

	health -= 10

	sprite.play("Hurt")

	if hud:
		hud.take_damage(10)

	if health <= 0:
		die()

func _successful_parry():

	health = min(MAX_HEALTH, health + PARRY_HEAL)

	if hud:
		hud.heal(PARRY_HEAL)

	sprite.modulate = Color(0.2, 1.0, 0.2, 1.0)

	await get_tree().create_timer(0.15).timeout

	sprite.modulate = Color(1, 1, 1, 1)

func die():

	if is_dead:
		return

	is_dead = true

	sprite.play("Death")

	set_physics_process(false)
	set_process_input(false)

func _update_animation():

	if is_dead:
		return

	if sprite.animation == "Land" and sprite.is_playing():
		return

	if sprite.animation == "Inhale" and sprite.is_playing():
		return

	if sprite.animation == "Hurt" and sprite.is_playing():
		return

	if sprite.animation == "Parry" and sprite.is_playing():
		return

	if current_attack != "" and sprite.is_playing():
		return

	var dir_x = Input.get_axis("move_left", "move_right")

	if is_jumping:

		if jump_y < 0:

			if flap_count == 0:
				sprite.play("Jump")

			elif sprite.animation != "Flapping" and sprite.animation != "Inhale":
				sprite.play("Flapping")

		else:

			if flap_count == 0:
				sprite.play("Falling")

	elif is_crouching:

		if dir_x != 0:

			sprite.play("Crouchwalk")
			sprite.flip_h = dir_x < 0

		else:
			sprite.play("Crouched")

	elif dir_x != 0 or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):

		sprite.play("Moving")

		if dir_x != 0:
			sprite.flip_h = dir_x < 0

	else:
		sprite.play("Idle")
