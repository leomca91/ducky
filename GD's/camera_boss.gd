extends Camera2D

func _ready():
	zoom         = Vector2(3, 3)
	limit_left   = 0
	limit_right  = 1000
	limit_top    = 0
	limit_bottom = 600

func _process(_delta):
	# fixed camera for boss room — centred on room
	global_position.x = 500
	global_position.y = 324
