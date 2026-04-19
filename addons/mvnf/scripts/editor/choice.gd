@tool
extends HBoxContainer
class_name Choice
@export var remove_button: Button
@export var choice_edit: LineEdit
var temp_name: String
var node: StoryNode

func _on_text_changed(new_text: String) -> void:
	print(temp_name)
	print(new_text)
	node.node_data.choices = rename_key_at_position(node.node_data.choices, temp_name, new_text).duplicate()
	print(node.node_data.choices)
	temp_name = new_text

func rename_key_at_position(dict: Dictionary, old_key, new_key) -> Dictionary:
	if dict.has(new_key):
		choice_edit.text = old_key
		return dict
	if not dict.has(old_key):
		return dict
	var new_dict = {}
	for key in dict.keys():
		if key == old_key:
			new_dict[new_key] = dict[old_key]
		else:
			new_dict[key] = dict[key]
	return new_dict
