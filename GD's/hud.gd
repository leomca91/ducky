extends CanvasLayer

var health_bar = null

func _ready():
	add_to_group("hud")
	# try both capitalisations just in case
	health_bar = get_node_or_null("Healthbar")
	if health_bar == null:
		health_bar = get_node_or_null("HealthBar")
	if health_bar == null:
		health_bar = get_node_or_null("health_bar")
	print("health_bar found: ", health_bar)

func set_max_health(amount: int):
	if health_bar == null:
		return
	health_bar.set_max_health(amount)

func take_damage(amount: int):
	if health_bar == null:
		return
	return health_bar.take_damage(amount)

func heal(amount: int):
	if health_bar == null:
		return
	health_bar.heal(amount)
