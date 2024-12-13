extends Object
"""Create various sections of a dispatcher node script"""


func create_dispatch_script_header() -> String:
	return """
extends Node
\"\"\" 
Dispatcher script initial created by compute_dispatch_generator
Addon found at https://github.com/MichaelReel/compute_dispatch_generator
\"\"\"

"""


func create_parameters_as_exports(data_types_by_id: Dictionary) -> String:
	# https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.4.60.html#basic-types
	var exports: String = ""
	for parameter_name in data_types_by_id:
		exports += _create_parameter_as_export(parameter_name, data_types_by_id[parameter_name])
	
	return exports


func _create_parameter_as_export(parameter_name: String, glsl_data_type: String) -> String:
	var export_parameter_name: String = _scriptify_parameter_name(parameter_name)
	var export_data_type: String = _scriptify_data_type(glsl_data_type)
	var export_definition: String = (
		"@export var {name}: {data_type}\n".format({
			"name": export_parameter_name,
			"data_type": export_data_type,
		})
	)
	return export_definition


func create_parameter_list(qualifiers_by_id: Dictionary) -> String:
	var parameter_definitions: String = ""
	for parameter_name in qualifiers_by_id:
		parameter_definitions += _create_parameter_definition(parameter_name, qualifiers_by_id[parameter_name])
	return parameter_definitions


func _create_parameter_definition(parameter_name: String, qualifiers: PackedStringArray) -> String:
	var parameter_definition: String = """
	{parameter_name},""".format({
		"parameter_name": parameter_name,
	})
	
	return parameter_definition


func create_displatch_with_exports_function(qualifiers_by_id: Dictionary, file_path: String) -> String:
	return ""


func begin_dispatch_function_with_rd(file_path: String, parameter_definitions: String) -> String:
	return """
func dispatch({parameter_definitions}
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
	"parameter_definitions": parameter_definitions,
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
