extends CanvasLayer

func _ready():
	add_to_group("death_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible      = false    # hide immediately, before creating any children

	var bg               = ColorRect.new()
	bg.color             = Color(0.1, 0, 0, 1)
	bg.anchors_preset    = Control.PRESET_FULL_RECT
	add_child(bg)

	var label                  = Label.new()
	label.text                 = "YOU DIED"
	label.anchors_preset       = Control.PRESET_CENTER
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1, 1))
	label.offset_left          = -250
	label.offset_right         = 250
	label.offset_top           = -100
	label.offset_bottom        = -20
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	add_child(label)

	var retry_btn               = Button.new()
	retry_btn.text              = "Retry"
	retry_btn.anchor_left       = 0.5
	retry_btn.anchor_right      = 0.5
	retry_btn.anchor_top        = 0.5
	retry_btn.anchor_bottom     = 0.5
	retry_btn.offset_left       = -100
	retry_btn.offset_right      = 100
	retry_btn.offset_top        = 20
	retry_btn.offset_bottom     = 70
	retry_btn.add_theme_font_size_override("font_size", 28)
	retry_btn.pressed.connect(_on_retry)
	add_child(retry_btn)

	var quit_btn                = Button.new()
	quit_btn.text               = "Quit"
	quit_btn.anchor_left        = 0.5
	quit_btn.anchor_right       = 0.5
	quit_btn.anchor_top         = 0.5
	quit_btn.anchor_bottom      = 0.5
	quit_btn.offset_left        = -100
	quit_btn.offset_right       = 100
	quit_btn.offset_top         = 80
	quit_btn.offset_bottom      = 130
	quit_btn.add_theme_font_size_override("font_size", 28)
	quit_btn.pressed.connect(_on_quit)
	add_child(quit_btn)

func show_death_screen():
	visible = true
	var tween = create_tween()
	for child in get_children():
		child.modulate.a = 0.0
		tween.parallel().tween_property(child, "modulate:a", 1.0, 0.6)

func _on_retry():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
