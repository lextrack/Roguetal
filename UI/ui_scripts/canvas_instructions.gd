extends CanvasLayer

@export var display_time : float = 3.0
var timer : Timer
var instructions_pages = [
	{	# CONTROL INSTRUCTIONS
		"images": [
			"res://UI/images_instructions/btn_xb_l0.png",
			"res://UI/images_instructions/wasd.png",
		],
		"texts": [
			"Move and control the character"
		]
	},
	{	# TALK INSTRUCCIONS
		"images": [
			"res://UI/images_instructions/btn_xb_01a.png",
			"res://UI/images_instructions/letter-e.png"
		],
		"texts": [
			"[color=yellow]Talk[/color] with people"
		]
	},
	{	# PAUSE INSTRUCTIONS
		"images": [
			"res://UI/images_instructions/btn_xb_12.png",
			"res://UI/images_instructions/letter-esc.png"
		],
		"texts": [
			"[color=yellow]Pause[/color] the game if you are bored"
		]
	},
]

var current_page_index = 0

func _ready():
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

func show_instructions_page(index: int):
	if index < instructions_pages.size():
		var page = instructions_pages[index]
		
		var images_container = $PanelInstructions/ImagesContainer
		var text_container = $PanelInstructions/TextContainer
		for container in [images_container, text_container]:
			for child in container.get_children():
				child.queue_free()
		
		for image_path in page["images"]:
			var texture_rect = TextureRect.new()
			texture_rect.texture = load(image_path)
			texture_rect.expand = true
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.custom_minimum_size = Vector2(50, 50)
			images_container.add_child(texture_rect)
		
		for text in page["texts"]:
			var rich_label = RichTextLabel.new()
			rich_label.bbcode_enabled = true
			rich_label.bbcode_text = text
			rich_label.fit_content = true
			rich_label.custom_minimum_size = Vector2(0, 20)
			text_container.add_child(rich_label)
		
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
