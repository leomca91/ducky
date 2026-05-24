extends Camera2D

var player = null

func _ready():
	player       = get_tree().get_first_node_in_group("player")
	zoom         = Vector2(3, 3)
	limit_left   = 0
	limit_right  = 100000
	limit_top    = 0
	limit_bottom = 600

func _process(_delta):
	if player == null:
		return
	global_position.x = player.global_position.x
	global_position.y = 324
	
