extends Node2D

@export var platform_width = 64.0

var debug_rect = null

func _ready():
	add_to_group("platforms")

	# thin visible sliver for positioning — hide later
	debug_rect               = ColorRect.new()
	debug_rect.color         = Color(1, 0, 0, 0.7)    # bright red so easy to see
	debug_rect.size          = Vector2(platform_width, 3.0)    # very thin line
	debug_rect.position      = Vector2(-platform_width * 0.5, -1.5)    # centred on node
	add_child(debug_rect)
