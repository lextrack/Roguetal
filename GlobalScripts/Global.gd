extends Node

var camera = null
var has_shown_intro = false
var graphics_configured = false

func _ready():
	if not graphics_configured:
		configure_graphics()

func configure_graphics():
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	Engine.max_fps = 120
	graphics_configured = true

func reset():
	has_shown_intro = false
   
