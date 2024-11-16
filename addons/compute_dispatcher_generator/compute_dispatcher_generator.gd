@tool
extends EditorPlugin


var tool_menu_text: String = "Generate GLSL Compute Dispatcher..."


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	self.add_tool_menu_item(tool_menu_text, dispatcher_create)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	self.remove_tool_menu_item(tool_menu_text)


func dispatcher_create() -> void:
	"""The main method for the dispatcher generator"""
	
	print_debug("dispatcher_create started")
	
	# Get the glsl file content
	# parse for layout local size
	# parse for each input and output
	# create a script with:
	# - some tool identifiable header
	# - comment/doc indicating the file is generated and giving information
	# - proper exports for setting up inputs
	# - proper functions for extracting outputs
	# - signals for completion
	
	print_debug("dispatcher_create complete")
