@tool
extends Object


func get_token_dictionary_from_glsl_file(filename: String) -> Dictionary:
	var token_dict: Dictionary = {}
	var file: FileAccess = FileAccess.open(filename, FileAccess.READ)
	var content: String = file.get_as_text()
	
	# Get all the buffer lines, denoted by the layout keyword
	var buffer_lines: PackedStringArray = _get_in_out_buffer_lines(content)
	
	# Extract the work groud qualifier and separate it from the other buffer lines
	var layout_vector: Vector3i = Vector3i.ZERO
	var i: int = 0
	while i < len(buffer_lines):
		var buffer_line: String = buffer_lines[i]
		if _is_work_group_size_line(buffer_line):
			layout_vector = _get_work_group_size_from_line(buffer_line)
			buffer_lines.remove_at(i)
		else:
			i += 1
	
	# Pull apart each buffer line and extract the relevant configuration
	var qualifiers_by_id: Dictionary = {}
	for buffer_line in buffer_lines:
		
		var buffer_name: String = _get_buffer_identifier_from_line(buffer_line)
		var qualifiers: PackedStringArray = PackedStringArray()
		qualifiers.append_array(_get_layout_qualifiers_from_line(buffer_line))
		qualifiers.append_array(_get_memory_qualifiers_from_line(buffer_line))
		qualifiers.append_array(_get_storage_qualifiers_from_line(buffer_line))
		qualifiers_by_id[buffer_name] = qualifiers
	
	# Pull out the actual data type from the line
	var data_types_by_id: Dictionary = {}
	for buffer_line in buffer_lines:
		var buffer_name: String = _get_buffer_identifier_from_line(buffer_line)
		var data_type: String = _get_data_type_from_buffer_line(buffer_line, buffer_name)
		data_types_by_id[buffer_name] = data_type
	
	# Get a list of possible set_ids
	var set_ids_dict: Dictionary = {}
	for id in qualifiers_by_id:
		var qualifiers: PackedStringArray = qualifiers_by_id[id]
		for qualifier: String in qualifiers:
			if qualifier.begins_with("set"):
				set_ids_dict[int(qualifier.rsplit("=")[1])] = null
	
	# Put together a response dictionary 
	token_dict["glsl_local_size"] = {
		"value": layout_vector,
		"type": "Vector3i",
	}
	token_dict["buffer_debug"] = buffer_lines
	token_dict["qualifiers_by_id"] = qualifiers_by_id
	token_dict["data_types_by_id"] = data_types_by_id
	token_dict["set_ids"] = set_ids_dict.keys()
	
	return token_dict



func _get_in_out_buffer_lines(content: String) -> PackedStringArray:
	"""Return array of 'layout' definitions lifted from the shader"""
	
	var regex: RegEx = RegEx.create_from_string(r"layout(?:\n|[^{};])*(?:{(?:\n|[^{}])*})?(?:\n|[^{};])*;")
	# Regex breakdown:
	# 
	# layout                    - Line starts with the layout keyword
	# (?:\n|[^{};])*            - Any number of newlines or other non { or } or ; characters
	# (?:{                      \
	#   (?:\n|[^{}])*            } - A block delimited by { and } with any number newlines and non block characters
	# })?                       / 
	# (?:\n|[^{};])*            - Any number of newlines or other non { or } or ; characters
	# ;                         - final statement delimiter
	
	var results: Array[RegExMatch] = regex.search_all(content)
	var buffer_lines: PackedStringArray = PackedStringArray()
	
	for result: RegExMatch in results:
		buffer_lines.append(result.get_string())
	
	return buffer_lines


func _is_work_group_size_line(glsl_line: String) -> bool:
	"""Return true if this line is the work-group size qualifier"""
	var regex: RegEx = RegEx.create_from_string(r"local_size_[xyz]")
	return regex.search(glsl_line) != null


func _get_work_group_size_from_line(content: String) -> Vector3i:
	"""Return the workgroup size as 3D integer vector"""
	# TODO: Need to account for fewer than 3 dimensions defined
	
	var regex: RegEx = RegEx.create_from_string(r"layout\s*\(local_size_x\s*=\s*(\d+)\s*,\s*local_size_y\s*=\s*(\d+)\s*,\s*local_size_z\s*=\s*(\d+)\s*\)\s*in\s*;")
	var result: RegExMatch = regex.search(content)
	
	return Vector3i(
		int(result.strings[1]),
		int(result.strings[2]),
		int(result.strings[3]),
	)


func _get_buffer_identifier_from_line(line: String) -> String:
	"""Get the last token on the line, should be the identifier"""
	var regex: RegEx = RegEx.create_from_string(r"layout(?:\n|.)*\s+([\w\d]*)\s*;")
	var results: RegExMatch = regex.search(line)
	return results.strings[1]


func _get_layout_qualifiers_from_line(line: String) -> PackedStringArray:
	"""Return an array containing all the layout qualifiers in this line"""
	
	# https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.4.60.html#layout-qualifiers
	
	var regex_as_string: String = (
		r"[(){},\s\n]" +
		r"(shared|" + 
		r"packed|" + 
		r"std140|" + 
		r"std430|" + 
		r"row_major|" + 
		r"column_major|" +
		r"binding\s*=\s*\d+|" +
		r"offset\s*=\s*\d+|" +
		r"align\s*=\s*\d+|" +
		r"set\s*=\s*\d+|" +
		r"push_constant|" +
		r"input_attachment_index\s*=\s*\d+|" +
		r"location\s*=\s*\d+|" +
		r"index\s*=\s*\d+|" +
		r"rgba32f|" +
		r"rgba16f|" +
		r"rg32f|" +
		r"rg16f|" +
		r"r11f_g11f_b10f|" +
		r"r32f|" +
		r"r16f|" +
		r"rgba16|" +
		r"rgb10_a2|" +
		r"rgba8|" +
		r"rg16|" +
		r"rg8|" +
		r"r16|" +
		r"r8|" +
		r"rgba16_snorm|" +
		r"rgba8_snorm|" +
		r"rg16_snorm|" +
		r"rg8_snorm|" +
		r"r16_snorm|" +
		r"r8_snorm|" +
		r"rgba32i|" +
		r"rgba16i|" +
		r"rgba8i|" +
		r"rg32i|" +
		r"rg16i|" +
		r"rg8i|" +
		r"r32i|" +
		r"r16i|" +
		r"r8i|" +
		r"rgba32ui|" +
		r"rgba16ui|" +
		r"rgb10_a2ui|" +
		r"rgba8ui|" +
		r"rg32ui|" +
		r"rg16ui|" +
		r"rg8ui|" +
		r"r32ui|" +
		r"r16ui|" +
		r"r8ui)" +
		r"[(){},\s\n]"
	)
	var regex: RegEx = RegEx.create_from_string(regex_as_string)
	var results: Array[RegExMatch] = regex.search_all(line)
	var matching_qualifiers: PackedStringArray = PackedStringArray()
	for result: RegExMatch in results:
		matching_qualifiers.append(result.strings[1])
	
	return matching_qualifiers


func _get_memory_qualifiers_from_line(line: String) -> PackedStringArray:
	"""Return an array containing all the memory qualifiers in this line"""
	
	# https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.4.60.html#memory-qualifiers
	
	var regex_as_string: String = (
		r"[(){},\s\n]" +
		r"(coherent|" +
		r"volatile|" +
		r"restrict|" +
		r"readonly|" +
		r"writeonly)" +
		r"[(){},\s\n]"
	)
	var regex: RegEx = RegEx.create_from_string(regex_as_string)
	var results: Array[RegExMatch] = regex.search_all(line)
	var matching_qualifiers: PackedStringArray = PackedStringArray()
	for result: RegExMatch in results:
		matching_qualifiers.append(result.strings[1])
	
	return matching_qualifiers


func _get_storage_qualifiers_from_line(line: String) -> PackedStringArray:
	"""Return an array containing all the storage qualifiers in this line"""
	
	# https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.4.60.html#storage-qualifiers
	
	var regex_as_string: String = (
		r"[(){},\s\n]" +
		r"(in|" +
		r"const|" +
		r"varying|" +
		r"out|" +
		r"attribute|" +
		r"uniform|" +
		r"buffer|" +
		r"shared)" +
		r"[(){},\s\n]"
	)
	var regex: RegEx = RegEx.create_from_string(regex_as_string)
	var results: Array[RegExMatch] = regex.search_all(line)
	var matching_qualifiers: PackedStringArray = PackedStringArray()
	for result: RegExMatch in results:
		matching_qualifiers.append(result.strings[1])
	
	return matching_qualifiers

func _get_data_type_from_buffer_line(line: String, id: String) -> String:
	# https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.4.60.html#basic-types
	
	var regex_as_string: String = (
		r"\{" +                           # Start of block
		r"[\n\s]*" +                      # 
		r"([^\{\};]*)" +                  # TODO: Assuming a single array for now
		r"[\n\s]*;[\n\s]*" +              # ;
		r"\}" +                           # End of Block
		r"|" +                            # OR
		r"([^\s}]*)" +                    # Predefined type
		r"[\n\s]*" +                      # 
		r"(?:{id});".format({"id": id})   # Line will finish with the id
	)
	
	var regex: RegEx = RegEx.create_from_string(regex_as_string)
	var result: RegExMatch = regex.search(line)
	var data_definition: String = result.strings[1] + result.strings[2]
	
	return data_definition
