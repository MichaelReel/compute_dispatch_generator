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


func create_parameter_list(qualifiers_by_id: Dictionary) -> String:
	var parameter_definitions: String = ""
	for parameter_name in qualifiers_by_id:
		parameter_definitions += create_parameter_definition(parameter_name, qualifiers_by_id[parameter_name])
	return parameter_definitions

func create_parameter_definition(parameter_name: String, qualifiers: PackedStringArray) -> String:
	var parameter_definition: String = """
	{parameter_name},""".format({
		"parameter_name": parameter_name,
	})
	
	return parameter_definition


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
