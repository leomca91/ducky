extends CanvasLayer

const BAR_WIDTH  = 400.0
const BAR_HEIGHT = 20.0
const BAR_X      = 0.0
const BAR_Y      = 10.0
const BORDER     = 2.0

var max_health   = 100
var current_health = 100
var fill_bar     = null
var name_label   = null

func _ready():
	add_to_group("boss_hud")

	# centre the bar at top of screen
	var screen_w     = get_viewport().get_visible_rect().size.x
	var start_x      = (screen_w - BAR_WIDTH) * 0.5

	# boss name label
	name_label                  = Label.new()
	name_label.text             = "FROGGER"
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2, 1))
	name_label.position         = Vector2(start_x, BAR_Y - 24)
	name_label.size             = Vector2(BAR_WIDTH, 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_label)

	# black border
	var border        = ColorRect.new()
	border.color      = Color(0, 0, 0, 1)
	border.position   = Vector2(start_x - BORDER, BAR_Y - BORDER)
	border.size       = Vector2(BAR_WIDTH + BORDER * 2, BAR_HEIGHT + BORDER * 2)
	add_child(border)

	# dark bg
	var bg            = ColorRect.new()
	bg.color          = Color(0.2, 0.0, 0.0, 1)
	bg.position       = Vector2(start_x, BAR_Y)
	bg.size           = Vector2(BAR_WIDTH, BAR_HEIGHT)
	add_child(bg)

	# green fill
	fill_bar          = ColorRect.new()
	fill_bar.color    = Color(0.2, 0.9, 0.2, 1)
	fill_bar.position = Vector2(start_x, BAR_Y)
	fill_bar.size     = Vector2(BAR_WIDTH, BAR_HEIGHT)
	add_child(fill_bar)

func set_max_health(amount: int):
	max_health     = amount
	current_health = amount
	_update_bar()

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	_update_bar()

func heal_to_full():
	current_health = max_health
	_update_bar()
	# flash green on heal
	fill_bar.color = Color(1, 1, 1, 1)
	await get_tree().create_timer(0.1).timeout
	fill_bar.color = Color(0.2, 0.9, 0.2, 1)

func _update_bar():
	if fill_bar == null:
		return
	var pct         = float(current_health) / float(max_health)
	fill_bar.size.x = BAR_WIDTH * pct
	# colour shifts red at low health
	fill_bar.color  = Color(1.0 - pct, pct * 0.9, 0.1, 1)
