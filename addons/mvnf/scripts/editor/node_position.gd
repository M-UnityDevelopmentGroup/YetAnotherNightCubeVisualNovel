@tool
extends HBoxContainer
class_name Transform
@export var x: SpinBox
@export var y: SpinBox
var current_transform: Dictionary[String, float]
signal transform_changed(transform: Dictionary[String, float])

func _change_x(value: float) -> void:
	current_transform.set("x", value)
	transform_changed.emit(current_transform)

func _change_y(value: float) -> void:
	current_transform.set("y", value)
	transform_changed.emit(current_transform)
