@tool
extends EditorPlugin

var tool_menu_text: String = "Generate GLSL Compute Dispatcher..."
var file_dialog: EditorFileDialog = null

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_tool_menu_item(tool_menu_text, dispatcher_create)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_tool_menu_item(tool_menu_text)


func dispatcher_create() -> void:
	"""The main method for the dispatcher generator"""
	
	print_debug("dispatcher_create started")
	
	if EditorInterface.is_playing_scene():
		printerr("Unsafe to update or generate scripts while scene playing")
		return
	
	# Get the glsl file content
	file_dialog = EditorFileDialog.new()
	file_dialog.set_title("Select compute shader file")
	file_dialog.add_filter("*.glsl", "GLSL Shaders (*.glsl)")
	file_dialog.set_access(EditorFileDialog.Access.ACCESS_RESOURCES)
	file_dialog.file_selected.connect(create_dispatcher_from_filename)
	
	# The following settings _would_ be desirable, but they currently don't seem to work:
	file_dialog.set_current_path("res://")
	file_dialog.set_file_mode(EditorFileDialog.FileMode.FILE_MODE_OPEN_FILE)
	file_dialog.set_display_mode(EditorFileDialog.DisplayMode.DISPLAY_THUMBNAILS)
	
	# Let the dialog trigger then next steps
	EditorInterface.popup_dialog_centered(file_dialog)


func create_dispatcher_from_filename(filename: String) -> void:
	print_debug("GLSL file selected: ", filename)
	
	# parse for layout local size
	# parse for each input and output
	# Get the output destination for the script
	# create a script with:
	# - some tool identifiable header
	# - comment/doc indicating the file is generated and giving information
	# - proper exports for setting up inputs
	# - proper functions for extracting outputs
	# - signals for completion
	# May need to trigger the editor to indicate file added/changed
	
	print_debug("dispatcher_create complete")
