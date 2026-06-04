extends Node2D

# platform blocks upward movement at this Y value
# player cannot walk "behind" the platform (move to lower Y than this)
@export var platform_width = 64.0    # how wide the platform is in pixels

func _ready():
	add_to_group("platforms")
