extends Object


func get_token_dictionary_from_glsl_file(filename: String) -> Dictionary:
	var token_dict: Dictionary = {}
	var file: FileAccess = FileAccess.open(filename, FileAccess.READ)
	var content: String = file.get_as_text()
	
	token_dict["glsl_local_size"] = {
		"value": _get_layout_from_glsl(content),
		"type": "Vector3i",
	}
	
	token_dict["buffer_debug"] = _get_in_out_buffer_lines(content)
	
	return token_dict


func _get_layout_from_glsl(content: String) -> Vector3i:
	var regex: RegEx = RegEx.create_from_string(r"layout\s*\(local_size_x\s*=\s*(\d+)\s*,\s*local_size_y\s*=\s*(\d+)\s*,\s*local_size_z\s*=\s*(\d+)\s*\)")
	var result: RegExMatch = regex.search(content)
	
	return Vector3i(
		int(result.strings[1]),
		int(result.strings[2]),
		int(result.strings[3]),
	)


func _get_in_out_buffer_lines(content: String) -> PackedStringArray:
	# TODO: Need to account for multiline definitions with {} blocks
	#       Currently capturing up to the first ; in the block
	
	var regex: RegEx = RegEx.create_from_string(r"layout(?:\n|[^;])*;")
	var results: Array[RegExMatch] = regex.search_all(content)
	var buffer_lines: PackedStringArray = PackedStringArray()
	
	for result: RegExMatch in results:
		buffer_lines.append(result.get_string())
	
	return buffer_lines
