@tool
class_name StoryNode
extends GraphNode
@export var type_button: OptionButton
@export var node_text_edit: TextEdit
@export var node_name_option: OptionButton
@export var node_sprite_option: OptionButton
@export var node_character_sound_option: OptionButton
@export var node_background_option: OptionButton
@export var node_background_type_option: OptionButton
@export var node_background_sound_option: OptionButton
@export var choice_button: Button
@export var choice_label: Label
@export var text_label: Label
@export var text_edit_label: Label
@export var text_edit: TextEdit
@export var choice_template: PackedScene
@export var choice_slot_offset: int
@export var node_popup: PopupMenu
@export var default_transform: Dictionary[String, int] = {
	"position_x": 0,
	"position_y": 0,
	"size_x": 300,
	"size_y": 500
}
var current_editor: StoryEditor
var current_graph_edit: GraphEdit
var node_id: int
var node_type: node_types
var node_data: Dictionary
var choice_templates: Array[Choice]
var temp_text_edit_size: float
var temp_choice: Choice
var temp_choice_size_y: float = 32
enum node_types {
	text,
	choice
}

func _ready() -> void:
	type_button.item_selected.connect(_change_type)
	dragged.connect(_update_position)
	resize_end.connect(_update_size)
	text_edit.text_changed.connect(_update_text)
	node_name_option.item_selected.connect(_change_name)
	node_background_option.item_selected.connect(_change_background)
	if not choice_button.pressed.is_connected(_create_choice):
		choice_button.pressed.connect(_create_choice)
	_change_type(0)

func _update_position(_from: Vector2, to: Vector2) -> void:
	node_data.editor_transform.position_x = to.x
	node_data.editor_transform.position_y = to.y

func _update_size(new_size: Vector2):
	node_data.editor_transform.size_x = new_size.x
	node_data.editor_transform.size_y = new_size.y
	
func _update_text() -> void:
	node_data.text = text_edit.text
	
func _change_name(index: int) -> void:
	node_data.name = current_editor.character_enum.find_key(index)
	_update_name()

func _update_name() -> void:
	if not current_editor.character_enum.has(node_data.name) and not current_editor.character_enum.is_empty():
		node_data.name = current_editor.character_enum.keys()[0]
	set_enum(current_editor.sprite_enum.get(node_data.name), node_sprite_option, node_data.get_or_add("sprite",""))
	set_enum(current_editor.character_sound_enum.get(node_data.name), node_character_sound_option, node_data.get_or_add("sound",""))

func _update_name_enum() -> void:
	set_enum(current_editor.character_enum, node_name_option, node_data.get_or_add("name",""))
	
func _change_background(index: int) -> void:
	node_data.background = current_editor.background_enum.find_key(index)
	_update_name()

func _update_background() -> void:
	if not current_editor.background_enum.has(node_data.background) and not current_editor.background_enum.is_empty():
		node_data.background = current_editor.background_enum.keys()[0]
	set_enum(current_editor.background_type_enum.get(node_data.background), node_background_type_option, node_data.get_or_add("background_type",""))
	set_enum(current_editor.background_sound_enum.get(node_data.background), node_background_sound_option, node_data.get_or_add("background_sound",""))

func _update_background_enum() -> void:
	set_enum(current_editor.background_enum, node_background_option, node_data.get_or_add("background",""))

func set_node_properties(phrase: Dictionary, id: int, edit: GraphEdit, editor: StoryEditor) -> bool:
	current_graph_edit = edit
	current_editor = editor
	node_id = id
	name = str(id)
	title = str(id)
	node_data = phrase.duplicate(true)
	match node_data.type:
		"text":
			_change_type(0)
			type_button.selected = 0
		"choice":
			_change_type(1)
			type_button.selected = 1
	if node_data.has("choices"):
		for i in node_data.choices:
			_create_choice(i, node_data.choices.get(i, 0), false)
	node_data.get_or_add("editor_transform", default_transform)
	position_offset.x = node_data.editor_transform.position_x
	position_offset.y = node_data.editor_transform.position_y
	size.x = node_data.editor_transform.size_x
	size.y = node_data.editor_transform.size_y
	_update_name_enum()
	_update_background_enum()
	_update_background()
	_update_name()
	node_text_edit.text = node_data.text
	return true

func set_enum(current_enum: Dictionary[String, int], option: OptionButton, value: String) -> void:
	option.clear()
	for i in current_enum:
		option.add_item(i)
	if not value in current_enum and not current_enum.is_empty():
		value = current_enum.keys()[0]
		option.selected = 0
	elif current_enum.is_empty():
		value = ""
		option.selected = -1
	else:
		option.selected = current_enum[value]

func set_node_connections(edit: GraphEdit) -> void:
	for i in current_editor.nodes:
		match node_data.type:
			"text":
				if node_data.has("next") and i.node_id == node_data.next:
					edit.connect_node(self.name, 0, i.name, 0)
					return
			"choice":
				for j in node_data.choices:
					if i.node_id == node_data.choices.get(j):
						edit.connect_node(self.name, node_data.choices.keys().find(j), i.name, 0)
		
	
func _change_type(index: int) -> void:
	node_type = index as node_types
	match node_type:
		node_types.text:
			text_label.text = "text"
			node_data.type = "text"
			text_edit_label.show()
			size.y += text_edit_label.size.y
			choice_label.hide()
			for i in choice_templates:
				i.hide()
				size.y -= type_button.size.y
			set_slot_enabled_right(choice_slot_offset, true)
		node_types.choice:
			text_label.text = ""
			temp_text_edit_size = text_edit_label.size.y
			node_data.type = "choice"
			text_edit_label.hide()
			size.y -= temp_text_edit_size
			choice_label.show()
			for i in choice_templates:
				i.show()
				size.y += type_button.size.y
			set_slot_enabled_right(choice_slot_offset, false)
	
func _create_choice(text: String = "Choice", path: int = 0, add_to_dict: bool = true) -> void:
	if node_data.choices.has(text) and add_to_dict:
		text += str(node_data.choices.size())
	if add_to_dict:
		node_data.choices.set(text,path)
	temp_choice = choice_template.instantiate()
	temp_choice.choice_edit.text = text
	temp_choice.temp_name = text
	temp_choice.choice_edit.text_changed.connect(temp_choice._on_text_changed)
	temp_choice.node = self
	temp_choice.remove_button.pressed.connect(_remove_choice.bind(temp_choice))
	choice_templates.append(temp_choice)
	size.y += temp_choice_size_y
	add_child(temp_choice)
	set_slot_enabled_right(choice_templates.size()+choice_slot_offset, true)

func _remove_choice(choice: Choice) -> void:
	size.y -= temp_choice_size_y
	node_data.choices.erase(choice.choice_edit.text)
	choice.queue_free()
	choice_templates.erase(choice)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			node_popup.position = get_global_mouse_position()
			node_popup.popup()
			
