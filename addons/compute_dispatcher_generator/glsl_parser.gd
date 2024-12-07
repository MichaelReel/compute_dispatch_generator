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
	
	# TODO: Pull apart each buffer line and extract the relevant configuration
	
	# Put together a response dictionary 
	token_dict["glsl_local_size"] = {
		"value": layout_vector,
		"type": "Vector3i",
	}
	token_dict["buffer_debug"] = buffer_lines
	
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
