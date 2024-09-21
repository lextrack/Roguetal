extends CanvasLayer

@export var display_time : float = 10.0
var timer : Timer
var instructions_pages = [
	"Move and control the character using left and right stick or WASD and the mouse.",
	"When you enter the dungeon, shoot by pressing the RT button on the controller or the left mouse button.",
	"To change weapon press LB on the controller or C on the keyboard.",
	"That blonde hair girl has more information about this place. Press the A button on your controller or the E key on your keyboard to speak to her."
]
var current_page_index = 0

func _ready():
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = display_time
	timer.connect("timeout", Callable(self, "_on_timeout"))
	add_child(timer)
	
	$PanelInstructions.hide()
	$PanelInstructions.get_node("AnimationPanel").connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	if not Globals.has_shown_intro:
		show_instructions_page(0)
	else:
		$PanelInstructions.hide()

func show_instructions_page(index: int):
	if index < instructions_pages.size():
		$PanelInstructions.get_node("RichLabel").bbcode_text = instructions_pages[index]
		$PanelInstructions.get_node("AnimationPanel").play("fade_in")
		timer.start()
	else:
		print("Index out of bounds")

func _on_timeout():
	$PanelInstructions.get_node("AnimationPanel").play("fade_out")

func _on_animation_finished(anim_name: String):
	if anim_name == "fade_out":
		$PanelInstructions.hide()
		current_page_index += 1
		if current_page_index < instructions_pages.size():
			show_instructions_page(current_page_index)
		else:
			current_page_index = 0
			Globals.has_shown_intro = true

func reset_instructions():
	current_page_index = 0
	if not Globals.has_shown_intro:
		show_instructions_page(0)
