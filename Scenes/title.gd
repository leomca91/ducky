extends Node2D

func _ready():
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var play_btn               = Button.new()
	play_btn.text              = "Play"
	play_btn.anchor_left       = 0.5
	play_btn.anchor_right      = 0.5
	play_btn.offset_left       = -100
	play_btn.offset_right      = 100
	play_btn.offset_top        = 80
	play_btn.offset_bottom     = 130
	play_btn.add_theme_font_size_override("font_size", 28)
	play_btn.pressed.connect(_on_play)
	canvas.add_child(play_btn)

	var quit_btn                = Button.new()
	quit_btn.text               = "Quit"
	quit_btn.anchor_left        = 0.5
	quit_btn.anchor_right       = 0.5
	quit_btn.offset_left        = -100
	quit_btn.offset_right       = 100
	quit_btn.offset_top         = 140
	quit_btn.offset_bottom      = 190
	quit_btn.add_theme_font_size_override("font_size", 28)
	quit_btn.pressed.connect(_on_quit)
	canvas.add_child(quit_btn)

func _on_play():
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_quit():
	get_tree().quit()
