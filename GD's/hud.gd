extends CanvasLayer

const BAR_X          = 80.0    # pushed right to fit 2x icon
const BAR_Y          = 15.0
const BAR_WIDTH      = 200.0
const BAR_HEIGHT     = 16.0
const BORDER         = 2.0

var max_health       = 100
var current_health   = 100
var fill_bar         = null

@onready var icon    = $Icon

func _ready():
	add_to_group("hud")
	icon.play("idle")

	_make_rect(Color(0, 0, 0, 1),
		Vector2(BAR_X, BAR_Y),
		Vector2(BAR_WIDTH + BORDER * 2, BAR_HEIGHT + BORDER * 2))

	_make_rect(Color(1, 1, 1, 1),
		Vector2(BAR_X + BORDER, BAR_Y + BORDER),
		Vector2(BAR_WIDTH, BAR_HEIGHT))

	fill_bar = _make_rect(Color(0.9, 0.1, 0.1, 1),
		Vector2(BAR_X + BORDER, BAR_Y + BORDER),
		Vector2(BAR_WIDTH, BAR_HEIGHT))

func _make_rect(color: Color, pos: Vector2, size: Vector2) -> ColorRect:
	var rect      = ColorRect.new()
	rect.color    = color
	rect.position = pos
	rect.size     = size
	add_child(rect)
	return rect

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
