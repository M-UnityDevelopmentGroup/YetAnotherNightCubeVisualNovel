@tool
extends EditorPlugin

var path: String = get_script().resource_path.get_base_dir()
var DOCK_CONTENT_SCENE = load(path + "/editor.tscn")
var editor: StoryEditor
var story_editor: EditorDock
var editor_title: String = "Story Editor"

func _disable_plugin() -> void:
	remove_dock(story_editor)
	story_editor.queue_free()

func _enter_tree() -> void:
	story_editor = EditorDock.new()
	story_editor.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	editor = DOCK_CONTENT_SCENE.instantiate()
	editor._set_default_paths(path)
	story_editor.add_child(editor)
	story_editor.title = editor_title
	add_dock(story_editor)
