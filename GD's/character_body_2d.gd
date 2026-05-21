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
const SPECIAL_COOLDOWN   = 3.0
const LEFT_BOUNDARY      = 0.0      # player cannot go left of this

# attack damage values
const DMG_RIGHT_HOOK     = 5
const DMG_SPAM_ATTACK    = 2        # lower per hit since it hits many times
const DMG_FSMASH         = 12
const DMG_FTILT          = 10
const DMG_USMASH         = 18

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

var special_cooldown     = 0.0

var is_dead              = false
var is_hurt              = false
var is_parrying          = false

@onready var sprite      = $AnimatedSprite2D
@onready var camera      = $Camera2D

func _ready():
	sprite.animation_finished.connect(_on_animation_finished)
	position.y = FLOOR_BOTTOM

	# camera only scrolls right — locks left edge
	camera.limit_left    = int(LEFT_BOUNDARY)
	camera.limit_bottom  = 600
	camera.limit_top     = -200
	# right limit very large so it scrolls right freely
	camera.limit_right   = 100000

func _on_animation_finished():
	match sprite.animation:
		"RightHook", "SpamAttack", "Land":
			current_attack = ""
		"Fsmash", "Ftilt", "Usmash":
			current_attack = ""
		"Inhale":
			sprite.play("Flapping")
		"Roll1":
			is_rolling     = false
			current_attack = ""
		"Hurt":
			is_hurt        = false
		"Parry":
			is_parrying    = false
		"Death":
			pass

func _input(event):
	if is_dead:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			hold_timer = 0.0
			_start_attack("RightHook")
		else:
			hold_timer = 0.0
			if current_attack == "SpamAttack":
				current_attack = ""

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Q:
				if special_cooldown <= 0.0:
					_start_attack("Fsmash")
					special_cooldown = SPECIAL_COOLDOWN
			KEY_E:
				if special_cooldown <= 0.0:
					_start_attack("Ftilt")
					special_cooldown = SPECIAL_COOLDOWN
			KEY_R:
				if special_cooldown <= 0.0:
					_start_attack("Usmash")
					special_cooldown = SPECIAL_COOLDOWN
			KEY_F:
				if not is_parrying and not is_jumping:
					is_parrying = true
					sprite.play("Parry")
			KEY_SHIFT:
				_do_roll()

func _do_roll():
	if is_rolling:
		return
	is_rolling     = true
	roll_timer     = ROLL_DURATION
	current_attack = "Roll1"
	var dir_x      = Input.get_axis("move_left", "move_right")
	var dir_y      = Input.get_axis("move_up", "move_down")
	roll_dir_x     = dir_x if dir_x != 0 else (1.0 if not sprite.flip_h else -1.0)
	roll_dir_y     = dir_y
	if roll_dir_x != 0:
		sprite.flip_h = roll_dir_x < 0
	sprite.play("Roll1")

func _start_attack(attack_name: String):
	if is_dead:
		return
	current_attack = attack_name
	sprite.play(attack_name)

	# deal damage to any nearby enemies
	var damage = 0
	match attack_name:
		"RightHook":  damage = DMG_RIGHT_HOOK
		"SpamAttack": damage = DMG_SPAM_ATTACK
		"Fsmash":     damage = DMG_FSMASH
		"Ftilt":      damage = DMG_FTILT
		"Usmash":     damage = DMG_USMASH

	if damage > 0:
		_hit_nearby_enemies(damage)

func _hit_nearby_enemies(damage: int):
	# find all enemies in the scene and check distance
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < 60.0:    # attack reach in pixels
			enemy.take_damage(damage, global_position)

func _physics_process(delta):
	if is_dead:
		return

	if special_cooldown > 0.0:
		special_cooldown -= delta

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		hold_timer += delta
		if hold_timer >= SPAM_HOLD_TIME and current_attack != "SpamAttack":
			_start_attack("SpamAttack")
	else:
		hold_timer = 0.0

	is_crouching = Input.is_action_pressed("crouch") and not is_jumping and not is_rolling

	if is_rolling:
		roll_timer -= delta
		position.x += roll_dir_x * ROLL_SPEED * delta
		if is_jumping:
			if roll_dir_y != 0:
				visual_offset += roll_dir_y * ROLL_DEPTH_SPEED * delta
			jump_y        += FALL_GRAVITY * delta * 0.8
			visual_offset += jump_y * delta
			if visual_offset >= 0.0:
				visual_offset  = 0.0
				jump_y         = 0.0
				is_jumping     = false
				flap_count     = 0
				has_inhaled    = false
				sprite.play("Land")
		else:
			if roll_dir_y != 0:
				position.y += roll_dir_y * ROLL_DEPTH_SPEED * delta
				position.y  = clamp(position.y, FLOOR_TOP, FLOOR_BOTTOM)
		if roll_timer <= 0.0:
			is_rolling     = false
			current_attack = ""
	else:
		var dir_x   = Input.get_axis("move_left", "move_right")
		var spd     = SPEED * CROUCH_SPEED_MULT if is_crouching else SPEED
		position.x += dir_x * spd * delta

		if dir_x != 0:
			sprite.flip_h = dir_x < 0

		if not is_jumping and not is_crouching:
			var dir_y   = Input.get_axis("move_up", "move_down")
			position.y += dir_y * DEPTH_SPEED * delta
			position.y  = clamp(position.y, FLOOR_TOP, FLOOR_BOTTOM)

	# clamp left boundary
	position.x = max(position.x, LEFT_BOUNDARY)

	if Input.is_action_just_pressed("jump") and not is_dead:
		if not is_jumping:
			is_jumping      = true
			has_inhaled     = false
			flap_count      = 0
			jump_y          = JUMP_VEL
			jump_hold_timer = 0.0
			is_holding_jump = true
			visual_offset   = 0.0
			current_attack  = ""
			sprite.play("Jump")
		elif flap_count < MAX_FLAPS:
			flap_count     += 1
			jump_y          = FLAP_VEL
			is_holding_jump = false
			if not has_inhaled:
				has_inhaled = true
				sprite.play("Inhale")
			else:
				sprite.play("Flapping")

	if is_holding_jump and Input.is_action_pressed("jump"):
		jump_hold_timer += delta
		if jump_hold_timer < JUMP_HOLD_TIME:
			jump_y = lerp(jump_y, JUMP_HOLD_BOOST, 0.3)
		else:
			is_holding_jump = false
	else:
		is_holding_jump = false

	if is_jumping and not is_rolling:
		var grav       = GRAVITY if jump_y < 0 else FALL_GRAVITY
		jump_y        += grav * delta
		visual_offset += jump_y * delta

		if visual_offset >= 0.0:
			visual_offset  = 0.0
			jump_y         = 0.0
			is_jumping     = false
			flap_count     = 0
			has_inhaled    = false
			sprite.play("Land")

	sprite.position.y = visual_offset

	var t  = (position.y - FLOOR_TOP) / (FLOOR_BOTTOM - FLOOR_TOP)
	var sc = lerp(0.7, 1.0, t)
	scale  = Vector2(sc, sc)

	_update_animation()

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

func take_damage():
	if is_dead:
		return
	is_hurt = true
	sprite.play("Hurt")

func die():
	is_dead = true
	sprite.play("Death")
