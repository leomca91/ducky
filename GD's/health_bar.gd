extends Control

const BAR_X          = 12.0
const BAR_Y          = 12.0
const BAR_WIDTH      = 200.0
const BAR_HEIGHT     = 16.0
const BORDER         = 2.0

var max_health       = 100
var current_health   = 100
var fill_bar         = null

func _ready():
	for child in get_children():
		child.queue_free()

	# outer black border
	var border           = ColorRect.new()
	border.color         = Color(0, 0, 0, 1)
	border.position      = Vector2(BAR_X, BAR_Y)
	border.size          = Vector2(BAR_WIDTH + BORDER * 2, BAR_HEIGHT + BORDER * 2)
	add_child(border)

	# white background
	var white            = ColorRect.new()
	white.color          = Color(1, 1, 1, 1)
	white.position       = Vector2(BAR_X + BORDER, BAR_Y + BORDER)
	white.size           = Vector2(BAR_WIDTH, BAR_HEIGHT)
	add_child(white)

	# red fill on top
	fill_bar             = ColorRect.new()
	fill_bar.color       = Color(0.9, 0.1, 0.1, 1)
	fill_bar.position    = Vector2(BAR_X + BORDER, BAR_Y + BORDER)
	fill_bar.size        = Vector2(BAR_WIDTH, BAR_HEIGHT)
	add_child(fill_bar)

	# small green icon on the left to match your PNG style
	var icon             = ColorRect.new()
	icon.color           = Color(0.1, 0.6, 0.3, 1)
	icon.position        = Vector2(BAR_X - 14, BAR_Y)
	icon.size            = Vector2(10, BAR_HEIGHT + BORDER * 2)
	add_child(icon)

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
