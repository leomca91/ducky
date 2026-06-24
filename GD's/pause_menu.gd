extends CanvasLayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible      = false

	var bg               = ColorRect.new()
	bg.color             = Color(0, 0, 0, 0.7)
	bg.anchors_preset    = Control.PRESET_FULL_RECT
	add_child(bg)

	var label                  = Label.new()
	label.text                 = "PAUSED"
	label.anchors_preset       = Control.PRESET_CENTER
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.offset_left          = -250
	label.offset_right         = 250
	label.offset_top           = -120
	label.offset_bottom        = -40
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

	var resume_btn               = Button.new()
	resume_btn.text              = "Resume"
	resume_btn.anchor_left       = 0.5
	resume_btn.anchor_right      = 0.5
	resume_btn.anchor_top        = 0.5
	resume_btn.anchor_bottom     = 0.5
	resume_btn.offset_left       = -100
	resume_btn.offset_right      = 100
	resume_btn.offset_top        = 0
	resume_btn.offset_bottom     = 50
	resume_btn.add_theme_font_size_override("font_size", 26)
	resume_btn.pressed.connect(_on_resume)
	add_child(resume_btn)

	var restart_btn               = Button.new()
	restart_btn.text              = "Restart"
	restart_btn.anchor_left       = 0.5
	restart_btn.anchor_right      = 0.5
	restart_btn.anchor_top        = 0.5
	restart_btn.anchor_bottom     = 0.5
	restart_btn.offset_left       = -100
	restart_btn.offset_right      = 100
	restart_btn.offset_top        = 60
	restart_btn.offset_bottom     = 110
	restart_btn.add_theme_font_size_override("font_size", 26)
	restart_btn.pressed.connect(_on_restart)
	add_child(restart_btn)

	var quit_btn                = Button.new()
	quit_btn.text               = "Quit"
	quit_btn.anchor_left        = 0.5
	quit_btn.anchor_right       = 0.5
	quit_btn.anchor_top         = 0.5
	quit_btn.anchor_bottom      = 0.5
	quit_btn.offset_left        = -100
	quit_btn.offset_right       = 100
	quit_btn.offset_top         = 120
	quit_btn.offset_bottom      = 170
	quit_btn.add_theme_font_size_override("font_size", 26)
	quit_btn.pressed.connect(_on_quit)
	add_child(quit_btn)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_pause()

func _toggle_pause():
	if get_tree().paused:
		_on_resume()
	else:
		visible           = true
		get_tree().paused  = true

func _on_resume():
	visible           = false
	get_tree().paused  = false

func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
