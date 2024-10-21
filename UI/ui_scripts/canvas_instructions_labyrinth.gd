extends CanvasLayer

@export var display_time : float = 3.0
var timer : Timer
var instructions_pages = [
	{
		"images": [
			"res://UI/images_instructions/btn_xb_r2.png",
			"res://UI/images_instructions/mouse_click.png",
			"res://UI/images_instructions/space.png"
		],
		"texts": [
			"To [color=red]shoot[/color] at enemies (remember to hold down)"
		]
	},
	{
		"images": [
			"res://UI/images_instructions/btn_xb_l1.png",
			"res://UI/images_instructions/letter-c.png"
		],
		"texts": [
			"To [color=yellow]switch[/color] weapons"
		]
	},
	{
		"images": [
			"res://UI/images_instructions/btn_xb_r0.png",
			"res://UI/images_instructions/mouse_move.png"
		],
		"texts": [
			"To [color=yellow]control[/color] and direct the shots"
		]
	},
]
var current_page_index = 0

func _ready():
	apply_custom_font()
	
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = display_time
	timer.connect("timeout", Callable(self, "_on_timeout"))
	add_child(timer)
	
	$PanelInstructions.hide()
	$PanelInstructions/AnimationPanel.connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	if not Globals.has_shown_intro:
		show_instructions_page(0)
	else:
		$PanelInstructions.hide()

func apply_custom_font():
	var font = load("res://Fonts/visitor1.ttf")
	if font:
		var rich_label = $PanelInstructions/TextContainer/RichLabel
		rich_label.add_theme_font_override("normal_font", font)

func show_instructions_page(index: int):
	if index < instructions_pages.size():
		var page = instructions_pages[index]
		
		var images_container = $PanelInstructions/ImagesContainer
		var rich_label = $PanelInstructions/TextContainer/RichLabel
		
		for child in images_container.get_children():
			child.queue_free()
		rich_label.clear()
		
		for image_path in page["images"]:
			var texture_rect = TextureRect.new()
			texture_rect.texture = load(image_path)
			texture_rect.expand = true
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.custom_minimum_size = Vector2(50, 50)
			images_container.add_child(texture_rect)
		
		rich_label.bbcode_enabled = true 
		rich_label.text = page["texts"][0] 
		
		apply_custom_font()
		
		$PanelInstructions.show()
		$PanelInstructions/AnimationPanel.play("fade_in")
		timer.start()
	else:
		print("Index out of bounds")

func _on_timeout():
	$PanelInstructions/AnimationPanel.play("fade_out")

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
	if not Globals.has_shown_intro:
		current_page_index = 0
		show_instructions_page(0)
