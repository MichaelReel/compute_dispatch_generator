@tool
extends Object
"""Create various sections of a dispatcher node script"""


func get_local_file_name_as_class_name(filename: String) -> String:
	return filename.get_file().trim_suffix(".glsl").to_pascal_case()


func create_dispatch_script_header(node_name: String) -> String:
	return """class_name {node_name}
extends Node
\"\"\" 
Dispatcher script initial created by compute_dispatch_generator
Addon found at https://github.com/MichaelReel/compute_dispatch_generator
\"\"\"

""".format({"node_name": node_name})


func create_parameter_list(data_types_by_id: Dictionary) -> Array[String]:
	"""Return an array of the parameters with script definitions and default empty arrays"""
	var parameter_definitions: Array[String] = []
	for parameter_name in data_types_by_id:
		parameter_definitions.append(_create_parameter_definition(parameter_name, data_types_by_id[parameter_name]))
	return parameter_definitions


func _create_parameter_definition(parameter_name: String, glsl_data_type: String) -> String:
	var export_parameter_name: String = _scriptify_parameter_name(parameter_name)
	var export_data_type: String = _scriptify_data_type(glsl_data_type)
	
	var parameter_definition: String = "{name}: {data_type}".format({
		"name": export_parameter_name,
		"data_type": export_data_type,
	})
	
	return parameter_definition


func create_parameters_as_exports(parameter_definitions: Array[String]) -> String:
	"""Take the list of parameter definitions and return the export block"""
	return "".join(
		parameter_definitions.map(
			func (parameter_definition: String) -> String: return "@export var " + parameter_definition + "\n"
		)
	) 


func create_displatch_with_exports_function(parameter_list: Array[String], file_path: String) -> String:
	var parameter_list_str: String = ",\n        ".join(parameter_list)
	return """
func dispatch_using_exports() -> void:
	dispatch(
		{parameter_list}
	)
""".format({"parameter_list": parameter_list_str})


func begin_dispatch_function_with_rd(file_path: String, parameter_definitions: Array[String]) -> String:
	# Parameters don't need require here, strip them off
	var parameter_definition_str: String = ",\n    ".join(
		parameter_definitions.map(
			func (parameter_definition: String) -> String: return (
				parameter_definition.split(" = ")[0]
			)
		)
	)
	return """
func dispatch(
	{parameters}
) -> void:
	\"\"\"Perform dispatch for {file_path}\"\"\"
	
	# Create a local rendering device.
	var rd: RenderingDevice = RenderingServer.create_local_rendering_device()
	
	# Load GLSL shader
	var shader_file: RDShaderFile = load(\"{file_path}\") as RDShaderFile
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader: RID = rd.shader_create_from_spirv(shader_spirv)
	
""".format({
	"file_path": file_path,
	"parameters": parameter_definition_str,
})


func _scriptify_parameter_name(parameter_name: String) -> String:
	var script_parameter_name: String = parameter_name.to_snake_case()
	return script_parameter_name

func _scriptify_data_type(glsl_data_type: String) -> String:
	if glsl_data_type.ends_with("[]"):
		return _scriptify_array_data_type(glsl_data_type)
	if glsl_data_type == "image2D":
		return "Texture2D"
	
	return glsl_data_type

func _scriptify_array_data_type(glsl_data_type: String) -> String:
	if glsl_data_type.begins_with("int"):
		return "PackedInt32Array = []"
	if glsl_data_type.begins_with("float"):
		return "PackedFloat32Array = []"
	return glsl_data_type
