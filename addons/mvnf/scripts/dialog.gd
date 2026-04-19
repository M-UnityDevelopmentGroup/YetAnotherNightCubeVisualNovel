class_name StoryPanel

extends Panel

signal proceed(type: String)
@export var NextButton: Button
@export var BackButton: Button
@export var ExitButton: Button
@export var ChoiceButton: PackedScene
@export var ChoicePanel: Panel
@export var ChoiceContainer: BoxContainer
@export var LabelPanel: Panel
@export var DialogPanel: Panel
@export var DialogImage: TextureRect
@export var BackgroundImage: TextureRect
@export var text: RichTextLabel
@export var character_name_text: RichTextLabel
@export var text_speed := 0.1
@export var background_stream: AudioStreamPlayer
@export var foreground_stream: AudioStreamPlayer
@export var StoryJSON: JSON
var current_stream: AudioStream
var current_text_speed: float 
var current_phrases: Array[Dictionary]
var current_index: int
var history: Array[int]
var phrase: Dictionary
var running := true
var is_busy: bool
var temp_choice_button: Button
var font_types = ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]

func _ready() -> void:
	NextButton.pressed.connect(next)
	BackButton.pressed.connect(back)
	ExitButton.pressed.connect(exit)
	current_text_speed = text_speed
	current_phrases.append_array(StoryJSON.data.phrases)
	await show_phrase()
	exit()

func show_phrase() -> bool:
	while running:
		if current_phrases[current_index].has("type"):
			phrase = current_phrases[current_index]
		match phrase.type:
			"text":
				await handle_phrase()
			"choice":
				await handle_choice()
		await proceed
	return true

func handle_choice() -> bool:
	character_name_text.text = phrase.name
	ChoiceContainer.mouse_filter = Control.MOUSE_FILTER_STOP
	await create_tween().tween_property(DialogPanel, "modulate:a", 0, 0.25).finished
	for choice in ChoiceContainer.get_children():
		choice.queue_free()
	for i in phrase.choices:
		temp_choice_button = ChoiceButton.instantiate()
		ChoiceContainer.add_child(temp_choice_button)
		temp_choice_button.text = i;
		temp_choice_button.pressed.connect(Callable(self, "next").bind(phrase.choices[i]))
	await create_tween().tween_property(ChoicePanel, "modulate:a", 1, 0.25).finished
	return true

func handle_phrase() -> bool:
	character_name_text.text = phrase.name
	text.visible_characters = 0
	phrase.get_or_add("sprite", "default")
	phrase.get_or_add("sound", "default")
	if StoryJSON.data.characters.has(phrase.name):
		DialogImage.texture = load(StoryJSON.data.characters.get(phrase.name).sprites.get(phrase.sprite))
		LabelPanel.self_modulate = StoryJSON.data.characters.get(phrase.name).colors.main
		if StoryJSON.data.characters.get(phrase.name).sounds.has(phrase.sound):
			foreground_stream.stream = load(StoryJSON.data.characters.get(phrase.name).sounds.get(phrase.sound))
	phrase.get_or_add("background", "default")
	phrase.get_or_add("background_sound", "default")
	if StoryJSON.data.backgrounds.has(phrase.background):
		BackgroundImage.texture = load(StoryJSON.data.backgrounds.get(phrase.background).sprites.get(phrase.background_type))
		BackgroundImage.expand_mode = StoryJSON.data.backgrounds.get(phrase.background).settings.expand_mode
		BackgroundImage.stretch_mode = StoryJSON.data.backgrounds.get(phrase.background).settings.stretch_mode
		self_modulate = StoryJSON.data.backgrounds.get(phrase.background).colors.main
		if StoryJSON.data.backgrounds.get(phrase.background).sounds.has(phrase.background_sound):
			current_stream = load(StoryJSON.data.backgrounds.get(phrase.background).sounds.get(phrase.background_sound))
			if not background_stream.stream == current_stream:
				background_stream.stream = current_stream
				background_stream.play()
	text.text = phrase.text
	if phrase.has("font_size"):
		for font_type in font_types:
			text.add_theme_font_size_override(font_type, phrase.font_size)
	is_busy = true
	while not text.visible_characters >= len(phrase.text):
		text.visible_characters += 1
		foreground_stream.play()
		if is_busy:
			await get_tree().create_timer(current_text_speed).timeout
		else:
			text.visible_ratio = 1
			break
	is_busy = false
	return true

func exit() -> void:
	get_tree().quit()
	proceed.emit()

func back() -> void:
	is_busy = false
	if current_phrases.size() == 1 or current_index < 0 or history.is_empty():
		current_index = 0
		return
	current_index = history.pop_at(-1)
	proceed.emit()

func next(next_index: int = -1) -> void:
	if is_busy:
		is_busy = false
		return
	if next_index != -1:
		ChoiceContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		current_text_speed = text_speed
		history.append(current_index)
		current_index = next_index
		create_tween().tween_property(ChoicePanel, "modulate:a", 0, 0.25)
		await create_tween().tween_property(DialogPanel, "modulate:a", 1, 0.25).finished
		for choice in ChoiceContainer.get_children():
			choice.queue_free()
	elif phrase.has("next"):
		current_text_speed = text_speed
		history.append(current_index)
		current_index = phrase.next
	else:
		running = false
	proceed.emit()
	
