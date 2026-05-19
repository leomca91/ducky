extends CharacterBody2D

const SPEED          = 150.0
const JUMP_VEL       = -400.0
const GRAVITY        = 800.0
const JUMP_HOLD_GRAV = 400.0
const DEPTH_SPEED    = 80.0
const FLOOR_TOP      = 300.0
const FLOOR_BOTTOM   = 415.0
const SPAM_HOLD_TIME = 0.4

var is_jumping       = false
var jump_y           = 0.0
var visual_offset    = 0.0
var hold_timer       = 0.0
var current_attack   = ""

@onready var sprite  = $AnimatedSprite2D

func _ready():
	sprite.animation_finished.connect(_on_animation_finished)
	position.y = FLOOR_BOTTOM

func _on_animation_finished():
	if sprite.animation in ["RightHook", "SpamAttack", "Land"]:
		current_attack = ""

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			hold_timer = 0.0
			_start_attack("RightHook")    # single click always right hook
		else:
			hold_timer = 0.0
			if current_attack == "SpamAttack":
				current_attack = ""

func _start_attack(attack_name: String):
	current_attack = attack_name
	sprite.play(attack_name)

func _physics_process(delta):
	# hold LMB to spam
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		hold_timer += delta
		if hold_timer >= SPAM_HOLD_TIME and current_attack != "SpamAttack":
			_start_attack("SpamAttack")
	else:
		hold_timer = 0.0

	# horizontal
	var dir_x      = Input.get_axis("move_left", "move_right")
	position.x    += dir_x * SPEED * delta

	# depth
	if not is_jumping:
		var dir_y   = Input.get_axis("move_up", "move_down")
		position.y += dir_y * DEPTH_SPEED * delta
		position.y  = clamp(position.y, FLOOR_TOP, FLOOR_BOTTOM)

	# jump
	if Input.is_action_just_pressed("jump") and not is_jumping:
		is_jumping     = true
		jump_y         = 0.0
		visual_offset  = 0.0
		current_attack = ""

	if is_jumping:
		if Input.is_action_pressed("jump") and jump_y > -150.0:
			jump_y += JUMP_VEL * delta
		else:
			jump_y += GRAVITY * delta * 0.5

		visual_offset += jump_y * delta

		if visual_offset >= 0.0:
			visual_offset  = 0.0
			jump_y         = 0.0
			is_jumping     = false
			sprite.play("Land")

	sprite.position.y = visual_offset

	var t  = (position.y - FLOOR_TOP) / (FLOOR_BOTTOM - FLOOR_TOP)
	var sc = lerp(0.7, 1.0, t)
	scale  = Vector2(sc, sc)

	_update_animation(dir_x)

func _update_animation(dir_x: float):
	if current_attack != "" and sprite.is_playing():
		if dir_x != 0:
			sprite.flip_h = dir_x < 0
		return

	if sprite.animation == "Land" and sprite.is_playing():
		return

	if is_jumping:
		if jump_y < 0:
			sprite.play("Jump")
		else:
			sprite.play("Falling")
	elif dir_x != 0 or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
		sprite.play("Moving")
		if dir_x != 0:
			sprite.flip_h = dir_x < 0
	else:
		sprite.play("Idle")
