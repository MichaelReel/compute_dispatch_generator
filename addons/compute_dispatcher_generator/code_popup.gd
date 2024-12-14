@tool
extends PopupPanel

@onready var code_edit: CodeEdit = $CodeEdit

func _ready() -> void:
	_set_to_center()

func show_code(code: String) -> void:
	code_edit.text = code
	code_edit.grab_focus()
	show()

func _set_to_center() -> void:
	position = (DisplayServer.window_get_size() / 2) - (size / 2)
