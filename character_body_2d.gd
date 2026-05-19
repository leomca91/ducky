extends CharacterBody2D

const SPEED          = 150.0
const JUMP_VEL       = -400.0
const GRAVITY        = 800.0
const JUMP_HOLD_GRAV = 400.0
const DEPTH_SPEED    = 80.0
const FLOOR_TOP      = 300.0    # highest point player can walk up to
const FLOOR_BOTTOM   = 400.0    # lowest point player can walk down to

var is_landing       = false
var is_jumping       = false
var jump_y           = 0.0      # y position when jump started
var visual_offset    = 0.0      # how high off the ground visually

@onready var sprite  = $AnimatedSprite2D

func _ready():
	sprite.animation_finished.connect(_on_animation_finished)
	position.y = FLOOR_BOTTOM   # start at the bottom

func _on_animation_finished():
	if sprite.animation == "Land":
		is_landing = false

func _physics_process(delta):
	# horizontal movement
	var dir_x = Input.get_axis("move_left", "move_right")
	position.x += dir_x * SPEED * delta

	# depth movement — only when not jumping
	if not is_jumping:
		var dir_y = Input.get_axis("move_up", "move_down")
		position.y += dir_y * DEPTH_SPEED * delta
		# clamp so player cant walk off top or bottom
		position.y = clamp(position.y, FLOOR_TOP, FLOOR_BOTTOM)

	# jumping — handled separately from depth
	if Input.is_action_just_pressed("jump") and not is_jumping:
		is_jumping   = true
		jump_y       = 0.0
		visual_offset = 0.0

	if is_jumping:
		if Input.is_action_pressed("jump") and jump_y > -150.0:
			jump_y += JUMP_VEL * delta          # hold for higher
		else:
			jump_y += GRAVITY * delta * 0.5     # fall back down

		visual_offset += jump_y * delta

		# landed back on ground
		if visual_offset >= 0.0:
			visual_offset = 0.0
			jump_y        = 0.0
			is_jumping    = false
			if not is_landing:
				is_landing = true
				sprite.play("Land")

	# apply visual offset — moves sprite up without affecting ground position
	sprite.position.y = visual_offset

	# scale for perspective — bigger at bottom, smaller at top
	var t     = (position.y - FLOOR_TOP) / (FLOOR_BOTTOM - FLOOR_TOP)
	var sc    = lerp(0.7, 1.0, t)
	scale     = Vector2(sc, sc)

	_update_animation(dir_x)

func _update_animation(dir_x: float):
	if is_landing:
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
