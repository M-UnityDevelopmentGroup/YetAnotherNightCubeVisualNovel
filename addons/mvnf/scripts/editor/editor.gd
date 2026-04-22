@tool
extends Control
class_name StoryEditor
@export var character_tree: Tree
@export var background_tree: Tree
@export var character_edit: CodeEdit
@export var background_edit: CodeEdit
@export var graph: GraphEdit
@export var story_path_label: RichTextLabel
@export var node_template: PackedScene
@export var story_actions_popup: PopupMenu
@export var create_actions_popup: MenuBar
@export var character_button: Button
@export var background_button: Button
@export var file_dialog: FileDialog
var current_story: Dictionary
var character_items: Dictionary[String,Array]
var background_items: Dictionary[String,Array]
var background_enum: Dictionary[String,int]
var background_type_enum: Dictionary[String,Dictionary]
var character_enum: Dictionary[String,int]
var sprite_enum: Dictionary[String, Dictionary]
var character_sound_enum: Dictionary[String, Dictionary]
var background_sound_enum: Dictionary[String, Dictionary]
var temp_node: StoryNode
var temp_node_data: Dictionary
var nodes: Array[StoryNode]
var temp_array: Array[TreeItem]
var temp_enum: Dictionary[String, int]
var tempi: int
var file: FileAccess
var file_content: String
var story_path: String
var current_story_action: story_actions
var story_template: Dictionary = {
	"characters": {
		"default": {
			"sprites": {
				"default": "res://icon.svg"
			},
			"colors": {
				"main": "6464FF"
			},
			"sounds": {
			}
		}
	},
	"backgrounds": {
		"default": {
			"sprites": {
				"default": "res://icon.svg"
			},
			"colors": {
				"main": "6464FF"
			},
			"sounds": {
				"default": ""
			},
			"settings": {
				"expand_mode": 0,
				"stretch_mode": 0
			}
		}
	},
	"phrases": [
	]
}
var template: Dictionary = {
	"type": "text",
	"name": "default",
	"sprite": "default",
	"sound": "default",
	"background": "default",
	"background_type": "default",
	"background_sound": "default",
	"text": "",
	"choices": {
	},
	"editor_transform": {
		"position_x": 0,
		"position_y": 0,
		"size_x": 300,
		"size_y": 500
	}
}
#var background: Dictionary = {
	#"sprites": {
	#},
	#"colors": {
	#},
	#"sounds": {
	#},
	#"settings": {
		#"expand_mode": 0,
		#"stretch_mode": 0
	#}
#}
#var character: Dictionary = {
	#"sprites": {
	#},
	#"colors": {
	#},
	#"sounds": {
	#},
#}

enum story_actions {
	NEW_STORY,
	OPEN_STORY,
	SAVE_STORY,
	SAVE_STORY_AS
}
enum create_actions {
	NODE,
	CHARACTER,
	BACKGROUND
}
func _ready() -> void:
	if not graph.connection_request.is_connected(connect_nodes):
		graph.connection_request.connect(connect_nodes)
	if not graph.disconnection_request.is_connected(disconnect_nodes):
		graph.disconnection_request.connect(disconnect_nodes)
	file_dialog.file_selected.connect(_process_file)
	character_button.pressed.connect(_update_characters)
	background_button.pressed.connect(_update_backgrounds)

func _set_default_paths(path: String) -> void:
	story_template.backgrounds.default.sprites.default = path + "/sprites/fallback/icon.svg"
	story_template.characters.default.sprites.default = path + "/sprites/fallback/icon.svg"
	story_template.backgrounds.default.sounds.default = path + "/sounds/fallback/default.mp3"
	story_template.characters.default.sounds.default = path + "/sounds/fallback/default.wav"


func _list_resourses_to_enum(resourses: Dictionary, enums: Dictionary[String, int]):
	for i in resourses:
		enums.get_or_add(i, len(enums))
		
func _list_resourses_to_enum_dict(resourses: Dictionary, enums: Dictionary[String, Dictionary], key: String):
	temp_enum.clear()
	for i in resourses:
		temp_enum.get_or_add(i, len(temp_enum))
	enums.get_or_add(key,temp_enum.duplicate(true))
	
func _manage_stories(id: int) -> void:
	current_story_action = id as story_actions
	match id as story_actions:
		story_actions.NEW_STORY:
			file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			file_dialog.popup_file_dialog()
		story_actions.OPEN_STORY:
			file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			file_dialog.popup_file_dialog()
		story_actions.SAVE_STORY:
			_update_story()
			file = FileAccess.open(story_path, FileAccess.WRITE)
			file.store_string(JSON.stringify(current_story.duplicate(true),"\t", false))
			file.close()
		story_actions.SAVE_STORY_AS:
			_update_story()
			file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			file_dialog.popup_file_dialog()

func _manage_nodes(id: int) ->  void:
	match id as create_actions:
		create_actions.NODE:
			temp_node = node_template.instantiate()
			graph.add_child(temp_node)
			temp_node_data.assign(template)
			current_story.phrases.append(temp_node_data)
			nodes.append(temp_node)
			temp_node.set_node_properties(temp_node_data, current_story.phrases.size() - 1, graph, self)
		

func _process_file(path: String) -> void:
	if not path.get_extension() == "json":
		push_error("Story is invalid")
		return
	match current_story_action:
		story_actions.NEW_STORY:
			if not FileAccess.file_exists(path):
				file = FileAccess.open(path, FileAccess.WRITE)
				file.store_string(JSON.stringify(story_template, "\t", false))
				current_story = story_template.duplicate(true)
				story_path = path
				story_path_label.text = story_path
				file.close()
				_open_story()
				story_actions_popup.set_item_disabled(3, false)
				story_actions_popup.set_item_disabled(4, false)
				create_actions_popup.show()
				return
		story_actions.OPEN_STORY:
			file = FileAccess.open(path, FileAccess.READ)
			file_content = file.get_as_text()
			if JSON.parse_string(file_content) == null:
				push_error("Story is invalid")
				file.close()
				return
			file.close()
			current_story = JSON.parse_string(file_content)
			story_path = path
			story_path_label.text = story_path
			_open_story()
			story_actions_popup.set_item_disabled(3, false)
			story_actions_popup.set_item_disabled(4, false)
			create_actions_popup.show()
			return
		story_actions.SAVE_STORY_AS:
			file = FileAccess.open(path, FileAccess.WRITE)
			file.store_string(JSON.stringify(current_story.duplicate(true),"\t", false))
			file.close()
			story_path = path
			story_path_label.text = story_path
			return

func _open_story() -> void:
	graph.clear_connections()
	tempi = 0
	for i in nodes:
		i.queue_free()
	nodes.clear()
	if current_story.has("backgrounds"):
		background_edit.text = JSON.stringify(current_story.backgrounds, "\t", false)
		_update_enums(current_story.backgrounds, background_enum, "sprites", background_type_enum, "sounds", background_sound_enum)
	if current_story.has("characters"):
		character_edit.text = JSON.stringify(current_story.characters, "\t", false)
		_update_enums(current_story.characters, character_enum, "sprites", sprite_enum, "sounds", character_sound_enum)
	if (current_story.has("phrases")):
		for i in current_story.phrases:
			temp_node = node_template.instantiate()
			graph.add_child(temp_node)
			nodes.append(temp_node)
			i.get_or_add("sprite", "default")
			i.get_or_add("background", background_enum.keys()[0])
			i.get_or_add("background_type", "default")
			if not character_enum.has(i.name) and not character_enum.is_empty():
				i.name = character_enum.keys()[0]
			if not background_enum.has(i.background):
				i.background = background_enum.keys()[0]
			if not background_type_enum.get(i.background).has(i.background_type):
				i.background_type = "default"
			if not sprite_enum.get(i.name).has(i.sprite):
				i.sprite = "default"
			temp_node.set_node_properties(i, tempi, graph, self)
			tempi+=1
		for i in nodes:
			i.set_node_connections(graph)

func _update_enums(first_dict: Dictionary, first_enum: Dictionary, key: String, second_enum: Dictionary, second_key: String, third_enum: Dictionary) -> void:
	first_enum.clear()
	second_enum.clear()
	third_enum.clear()
	_list_resourses_to_enum(first_dict, first_enum)
	for i in first_dict:
		if first_dict.get(i).has(key):
			_list_resourses_to_enum_dict(first_dict.get(i).get(key), second_enum, i)
		if first_dict.get(i).has(second_key):
			_list_resourses_to_enum_dict(first_dict.get(i).get(second_key), third_enum, i)

func _update_story() -> void:
	if JSON.parse_string(character_edit.text) == null or JSON.parse_string(background_edit.text) == null:
		return
	current_story.phrases.clear()
	current_story.characters = JSON.parse_string(character_edit.text)
	current_story.backgrounds = JSON.parse_string(background_edit.text)
	_update_enums(current_story.backgrounds, background_enum, "sprites", background_type_enum, "sounds", background_sound_enum)
	_update_enums(current_story.characters, character_enum, "sprites", sprite_enum, "sounds", character_sound_enum)
	for i in nodes:
		i._update_name_enum()
		i._update_background_enum()
		i._update_background()
		i._update_name()
		current_story.phrases.append(i.node_data.duplicate(true))

func _update_characters() -> void:
	if JSON.parse_string(character_edit.text) == null:
		character_button.modulate = Color(1,0,0)
		return
	character_button.modulate = Color(1,1,1)
	current_story.characters = JSON.parse_string(character_edit.text)
	_update_enums(current_story.characters, character_enum, "sprites", sprite_enum, "sounds", character_sound_enum)
	for i in nodes:
		i._update_name()
		i._update_name_enum()

func _update_backgrounds() -> void:
	if JSON.parse_string(background_edit.text) == null:
		background_button.modulate = Color(1,0,0)
		return
	background_button.modulate = Color(1,1,1)
	current_story.backgrounds = JSON.parse_string(background_edit.text)
	_update_enums(current_story.backgrounds, background_enum, "sprites", background_type_enum, "sounds", background_sound_enum)
	for i in nodes:
		i._update_background()
		i._update_background_enum()

#func _input(event):
	#if event is InputEventKey and event.pressed:
		#if event.keycode == KEY_S and event.ctrl_pressed and not story_path == null and not current_story.is_empty():
			#_manage_stories(2)
			
func connect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	if nodes[int(from_node)].node_data.type == "text":
		nodes[int(from_node)].node_data.next = int(to_node)
	else:
		nodes[int(from_node)].node_data.choices.set(nodes[int(from_node)].node_data.choices.keys()[from_port], int(to_node))
	graph.connect_node(from_node, from_port, to_node, to_port)

func disconnect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	if nodes[int(from_node)].node_data.type == "text":
		nodes[int(from_node)].node_data.erase("next")
	else:
		nodes[int(from_node)].node_data.choices.set(nodes[int(from_node)].node_data.choices.keys()[from_port], 0)
	graph.disconnect_node(from_node, from_port, to_node, to_port)
