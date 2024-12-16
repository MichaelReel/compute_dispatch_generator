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
			func (parameter_definition: String) -> String: return "@export var _" + parameter_definition + "\n"
		)
	)


func create_shader_references(size: Vector3i) -> String:
	return """
var _rd: RenderingDevice
var _shader: RID
var _glsl_local_size: Vector3i  = Vector3i({size_x}, {size_y} ,{size_z})
var _uniform_set : RID
var _bindings: Array[RDUniform] = []
""".format({
	"size_x": size.x,
	"size_y": size.y,
	"size_z": size.z,
})


func create_buffer_rid_references(data_types_by_id: Dictionary) -> String:
	var buffer_rids: String = ""
	for glsl_parameter_name in data_types_by_id:
		var parameter_name: String = _scriptify_parameter_name(glsl_parameter_name)
		buffer_rids += "var _{parameter_name}_rid: RID\n".format({"parameter_name": parameter_name})
	return buffer_rids


func create_displatch_with_exports_function(parameter_list: Array[String], file_path: String) -> String:
	var parameter_list_str: String = ",\n        _".join(parameter_list)
	return """
func dispatch_using_exports() -> void:
	dispatch(
		_{parameter_list}
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
	_rd = RenderingServer.create_local_rendering_device()
	
	# Load GLSL shader
	var shader_file: RDShaderFile = load(\"{file_path}\") as RDShaderFile
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	_shader = rd.shader_create_from_spirv(shader_spirv)
	
""".format({
	"file_path": file_path,
	"parameters": parameter_definition_str,
})


func get_scripted_parameter_names(data_types_by_id: Dictionary) -> Array[String]:
	var parameter_names: Array[String] = []
	for glsl_parameter_name in data_types_by_id:
		parameter_names.append(_scriptify_parameter_name(glsl_parameter_name))
	return parameter_names


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


func create_uniform_configurations(data_types_by_id: Dictionary, qualifiers_by_id: Dictionary) -> String:
	var uniform_configurations: String = ""
	for parameter_name in data_types_by_id:
		uniform_configurations += _create_uniform_configuration(
			parameter_name, data_types_by_id[parameter_name], qualifiers_by_id[parameter_name]
		)
	return uniform_configurations


func _create_uniform_configuration(parameter_name: String, data_type: String, qualifiers: Array[String]) -> String:
	var set_id: int = int()
	var binding_id: int = int()
	
	# TODO: Need to get the correct set and binding ids into the uniform script
	#       Also should group uniforms by set
	
	return """
	# Create storage for {parameter_name}
	var {parameter_name}_input_bytes: PackedByteArray = {parameter_name}.to_byte_array()
	var {parameter_name}_buffer: RID = rd.storage_buffer_create({parameter_name}_input_bytes.size(), {parameter_name}_input_bytes)
	var {parameter_name}_uniform := RDUniform.new()
	{parameter_name}_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	{parameter_name}_uniform.binding = 0 # this needs to match the "binding" in our shader file
	{parameter_name}_uniform.add_id({parameter_name}_buffer)
	
	var uniform_set := rd.uniform_set_create([uniform], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file
	""".format({
		"parameter_name": parameter_name,
	})
