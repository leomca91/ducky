extends Control

const BAR_X          = 40.0
const BAR_Y          = 12.0
const BAR_WIDTH      = 200.0
const BAR_HEIGHT     = 16.0
const BORDER         = 2.0
const ICON_SCALE     = 3.0
const FRAME_RATE     = 8.0

var max_health       = 100
var current_health   = 100
var fill_bar         = null
var icon_rect        = null
var frame_timer      = 0.0
var current_frame    = 0
var frame_textures   = []

func _ready():
	for child in get_children():
		child.queue_free()

	# slice PNG into 5 frame textures
	var tex  = preload("res://Sprites/UI/New Piskel (1).png")
	var iw   = tex.get_width() / 5
	var ih   = tex.get_height()
	for i in range(5):
		var atlas        = AtlasTexture.new()
		atlas.atlas      = tex
		atlas.region     = Rect2(i * iw, 0, iw, ih)
		frame_textures.append(atlas)

	# icon as TextureRect
	icon_rect                = TextureRect.new()
	icon_rect.texture        = frame_textures[0]
	icon_rect.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.size           = Vector2(iw * ICON_SCALE, ih * ICON_SCALE)
	icon_rect.position       = Vector2(BAR_X - iw * ICON_SCALE - 4, BAR_Y)
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(icon_rect)

	# black border
	var border        = ColorRect.new()
	border.color      = Color(0, 0, 0, 1)
	border.position   = Vector2(BAR_X, BAR_Y)
	border.size       = Vector2(BAR_WIDTH + BORDER * 2, BAR_HEIGHT + BORDER * 2)
	add_child(border)

	# white background
	var white         = ColorRect.new()
	white.color       = Color(1, 1, 1, 1)
	white.position    = Vector2(BAR_X + BORDER, BAR_Y + BORDER)
	white.size        = Vector2(BAR_WIDTH, BAR_HEIGHT)
	add_child(white)

	# red fill
	fill_bar          = ColorRect.new()
	fill_bar.color    = Color(0.9, 0.1, 0.1, 1)
	fill_bar.position = Vector2(BAR_X + BORDER, BAR_Y + BORDER)
	fill_bar.size     = Vector2(BAR_WIDTH, BAR_HEIGHT)
	add_child(fill_bar)

func _process(delta):
	# manually animate the icon
	if frame_textures.size() == 0 or icon_rect == null:
		return
	frame_timer += delta
	if frame_timer >= 1.0 / FRAME_RATE:
		frame_timer    = 0.0
		current_frame  = (current_frame + 1) % frame_textures.size()
		icon_rect.texture = frame_textures[current_frame]

func set_max_health(amount: int):
	max_health     = amount
	current_health = amount
	_update_bar()

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	_update_bar()
	return current_health <= 0

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	_update_bar()

func _update_bar():
	if fill_bar == null:
		return
	var pct         = float(current_health) / float(max_health)
	fill_bar.size.x = BAR_WIDTH * pct
