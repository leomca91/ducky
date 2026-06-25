extends CanvasLayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer        = 100

	var bg               = ColorRect.new()
	bg.color             = Color(0, 0, 0, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.size              = get_viewport().get_visible_rect().size
	add_child(bg)

	var label                  = Label.new()
	label.text                 = "VICTORY!"
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 1))
	label.offset_left          = -250
	label.offset_right         = 250
	label.offset_top           = -100
	label.offset_bottom        = -20
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

	var continue_btn               = Button.new()
	continue_btn.text              = "Continue"
	continue_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	continue_btn.offset_left       = -100
	continue_btn.offset_right      = 100
	continue_btn.offset_top        = 20
	continue_btn.offset_bottom     = 70
	continue_btn.add_theme_font_size_override("font_size", 28)
	continue_btn.pressed.connect(_on_continue)
	add_child(continue_btn)

func _on_continue():
	Engine.time_scale = 1.0
	queue_free()    # remove this win screen before changing scene
	get_tree().change_scene_to_file("res://Scenes/title.tscn")

func _exit_tree():
	print("Win screen removed")
