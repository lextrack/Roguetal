extends CanvasLayer

@export var display_time: float = 3.0
var timer: Timer
var instructions_pages = []
var current_page_index = 0

func _ready():
	initialize_timer()
	setup_panel()

	TranslationManager.language_changed.connect(load_instructions)
	load_instructions()
	apply_custom_font()
	
	if not Globals.has_shown_intro:
		await get_tree().process_frame
		show_instructions_page(0)
	else:
		$PanelInstructions.hide()
		
func initialize_timer():
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = display_time
	timer.connect("timeout", Callable(self, "_on_timeout"))
	add_child(timer)

func setup_panel():
	$PanelInstructions.hide()
	$PanelInstructions/AnimationPanel.connect("animation_finished", Callable(self, "_on_animation_finished"))

func load_instructions():
	if FileAccess.file_exists("res://Dialogues/instructions.json"):
		var json_as_text = FileAccess.open("res://Dialogues/instructions.json", FileAccess.READ)
		var json_as_dict = JSON.parse_string(json_as_text.get_as_text())
		if json_as_dict and TranslationManager.current_language in json_as_dict:
			instructions_pages = json_as_dict[TranslationManager.current_language].pages
			
			if $PanelInstructions.visible and current_page_index < instructions_pages.size():
				show_instructions_page(current_page_index)
		else:
			push_error("Error: Invalid instructions.json format or missing language")
	else:
		push_error("Error: Could not find instructions.json")
		instructions_pages = [{
			"images": [],
			"texts": ["Welcome to the game!"]
		}]

func apply_custom_font():
	var font = load("res://Fonts/Pixel Azure Bonds.otf")
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
		
		if timer:
			timer.start()

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
