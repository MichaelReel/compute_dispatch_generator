@tool
extends EditorPlugin
"""
The primary code for controlling the dispatcher script generation
"""

const GLSLParser: GDScript = preload("glsl_parser.gd")
const DispatchComponents: GDScript = preload("dispatcher_components.gd")
const CodePopup: GDScript = preload("code_popup.gd")
const CodePopupScene: PackedScene = preload("code_popup.tscn")

var tool_menu_text: String = "Generate GLSL Compute Dispatcher..."
var file_dialog: EditorFileDialog = null

var _glsl_parser: GLSLParser
var _dispatch_components: DispatchComponents
var _code_popup: CodePopup


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	_glsl_parser = GLSLParser.new()
	_dispatch_components = DispatchComponents.new()
	_code_popup = CodePopupScene.instantiate()
	get_editor_interface().get_base_control().add_child(_code_popup)
	add_tool_menu_item(tool_menu_text, dispatcher_create)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_tool_menu_item(tool_menu_text)
	get_editor_interface().get_base_control().remove_child(_code_popup)
	_code_popup.queue_free()
	_dispatch_components.queue_free()
	_glsl_parser.queue_free()


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


func display_code_in_popup(code: String) -> void:
	#print(code)
	_code_popup.show_code(code)


func create_dispatcher_from_filename(filename: String) -> void:
	print_debug("GLSL file selected: ", filename)
	
	# parse for layout local size
	var token_dict: Dictionary = _glsl_parser.get_token_dictionary_from_glsl_file(filename)
	
	print_debug(token_dict)
	# parse for each input and output
	# Get the output destination for the script
	# # Print to STDOUT for now?
	
	# create a script with:
	# - some tool identifiable header
	# - comment/doc indicating the file is generated and giving information
	# - proper exports for setting up inputs
	# - proper functions for extracting outputs
	# - signals for completion
	var header: String = _dispatch_components.create_dispatch_script_header()
	var exports: String = _dispatch_components.create_parameters_as_exports(token_dict["data_types_by_id"])
	var parameters: String = _dispatch_components.create_parameter_list(token_dict["qualifiers_by_id"])
	var export_func: String = _dispatch_components.create_displatch_with_exports_function(token_dict["qualifiers_by_id"], filename)
	var func_head: String = _dispatch_components.begin_dispatch_function_with_rd(filename, parameters)
	display_code_in_popup(
		header + exports + export_func + func_head
	)
	# May need to trigger the editor to indicate file added/changed
	
	
	print_debug("dispatcher_create complete")
