extends Node

var default_dir := "user://"
var suffix := "dat"

func settings_save() -> void:
	var path = "settings." + suffix
	var file
	
	file = file_open(path)
	file.store_buffer(Stats.game_settings)
	
	file = null

func settings_load() -> void:
	var path = "settings." + suffix
	var file
	
	if FileAccess.file_exists(default_dir + path):
		file = file_open(path)
		Stats.game_settings = file.get_buffer(file.get_length())
		file = null
	else:
		Stats.initialize_settings()
		settings_save()
		
	Stats.set_all_settings()

func window_save() -> void:
	var path = "window." + suffix
	var file
	
	var data = []
	var xpos = num_to_hex(int(DisplayServer.window_get_position().x), 6)
	data.append(base_convert(xpos.substr(0, 2), 16, 10).to_int())
	data.append(base_convert(xpos.substr(2, 2), 16, 10).to_int())
	data.append(base_convert(xpos.substr(4, 2), 16, 10).to_int())
	var ypos = num_to_hex(int(DisplayServer.window_get_position().y), 6)
	data.append(base_convert(ypos.substr(0, 2), 16, 10).to_int())
	data.append(base_convert(ypos.substr(2, 2), 16, 10).to_int())
	data.append(base_convert(ypos.substr(4, 2), 16, 10).to_int())
	
	file = file_open(path)
	file.store_buffer(data)
	
	file = null

func window_load() -> void:
	var path = "window." + suffix
	var file
	
	if FileAccess.file_exists(default_dir + path):
		file = file_open(path)
		var data = file.get_buffer(file.get_length())
		file = null
		var pos = Vector2.ZERO
		pos.x = combine_bytes([data[0], \
								data[1], \
								data[2]])
		pos.y = combine_bytes([data[3], \
								data[4], \
								data[5]])
		DisplayServer.window_set_position(pos)
	else:
		var current_screen = DisplayServer.window_get_current_screen()
		var screen_pos = DisplayServer.screen_get_position(current_screen)
		screen_pos = Vector2(screen_pos.x, screen_pos.y)
		var screen_size = DisplayServer.screen_get_size(current_screen)
		DisplayServer.window_set_position(screen_pos + screen_size * 0.5 - DisplayServer.window_get_size() * 0.5)
		window_save()

func data_save(index := 0) -> void:
	var path = "data." + suffix
	
	json_save(path, Stats.game_data, index, true)
	
	#if Global.current_room_control and Global.current_room_control.has_player:
	#	var n = Global.gui.get_node("HUD/SaveIcon/AnimationPlayer")
	#	if n.current_animation == "":
	#		n.play("appear")

func data_load(index := 0) -> void:
	var path = "data." + suffix
	
	if FileAccess.file_exists(default_dir + path):
		var data = json_load(path, index, true)
		
		if typeof(data) == TYPE_DICTIONARY and data[Stats.Data.version] == Stats.data_version:
			Stats.game_data = data
			#Stats.reset_global_vars()
			#TimeEvents.caught_up = false
		else:
			Stats.initialize_data()
			Stats.data_save(index)
	else:
		Stats.initialize_data()
		Stats.data_save(index)
		Stats.data_load(index)
	
func json_save(filename, data, index = -1, full_path = false):
	var json_string = JSON.stringify(data, "\t")
	var path = filename + ".json"
	if index != -1:
		path = "profile" + str(index) + "/" + path
	if full_path:
		path = filename
		
	var file
	file = file_open(path, FileAccess.WRITE)
	file.store_string(json_string)
	file = null
	
func json_load(filename, index = -1, full_path = false):
	var file
	var path = filename + ".json"
	if index != -1:
		path = "profile" + str(index) + "/" + path
	if full_path:
		path = filename
	
	file = file_open(path)
	var string = file.get_as_text()
	
	var json = JSON.new()
	var error = json.parse(string)
	if error == OK:
		var data = json.data
		if typeof(data) in [TYPE_ARRAY, TYPE_DICTIONARY]:
			return json_repair_keys(data)
		return -1
	return -2
	
func json_repair_keys(data):
	if typeof(data) == TYPE_ARRAY:
		var new_data = []
		for element in data:
			new_data.append(json_repair_keys(element))
		return new_data
	if typeof(data) == TYPE_DICTIONARY:
		var new_data = {}
		for key in data.keys():
			var new_val = json_repair_keys(data[key])
			if key.is_valid_int():
				new_data[key.to_int()] = new_val
			else:
				new_data[key] = new_val
		return new_data
	if typeof(data) == TYPE_FLOAT and abs(round(data) - data) < 0.001:
		data = int(round(data))
	return data
	
func file_delete(path: String) -> void:
	var dir = DirAccess.open(default_dir)
	dir.remove(path)

func file_create(path: String, full_dir = false):
	if !full_dir:
		path = default_dir + path
		
	DirAccess.make_dir_recursive_absolute(path.left(path.rfind('/') + 1))
	var file = FileAccess.open(path, FileAccess.WRITE)
	file = null
	
func file_open(path: String, access = FileAccess.READ_WRITE, full_dir = false):
	if !full_dir:
		path = default_dir + path
	if !FileAccess.file_exists(path):
		file_create(path, true)
		
	return FileAccess.open(path, access)
	
func find_files(path, recursive = true, whitelist = [], base = ""):
	var files = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if dir.current_is_dir():
				if recursive:
					var new_base = base
					if new_base != "":
						new_base += "/"
					new_base += file
					var new_files = find_files(path + "/" + file, true, whitelist, new_base)
					for new_file in new_files:
						files.append(new_file)
			else:
				var fail = false
				if !whitelist.is_empty():
					fail = true
					for entry in whitelist:
						if file.contains("." + entry):
							fail = false
							break
				if !fail:
					var new_base = base
					if new_base != "":
						new_base += "/"
					new_base += file
					files.append(new_base)
			file = dir.get_next()
	return files
	
func num_to_hex(number, buffer):
	number = dec_to_hex(number)
	while number.length() < buffer:
		number = "0" + number

	return number

func dec_to_hex(dec):
	var hex
	var h
	var byte
	var hi
	var lo
	if dec:
		hex = ""
	else:
		hex = "00"
	h = "0123456789ABCDEF"
	while (dec):
		byte = dec & 255;
		hi = h[byte / 16]
		lo = h[byte % 16]
		hex = hi + lo + hex
		dec = dec >> 8
	return hex
	
func hex_to_dec(hex):
	var dec
	var h = "0123456789ABCDEF"
	var p = 0
	hex = hex.to_upper()
	dec = 0
	while p < hex.length():
		dec = dec << 4 | h.find(hex[p])
		p += 1
	return dec
	
func base_convert(number, oldbase, newbase):
	var out = ""
	number = number.to_upper()

	var leng = number.length()
	var tab = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

	var i = 0
	var num = []
	while i < leng:
		num.append(tab.find(number[i]))
		i += 1

	while leng != 0:
		var divide = 0
		var newlen = 0
		i = 0
		while i < leng:
			divide = divide * oldbase + num[i];
			if (divide >= newbase):
				num[newlen] = divide / newbase
				newlen += 1
				divide = divide % newbase
			elif (newlen  > 0):
				num[newlen] = 0
				newlen += 1
			i += 1
		leng = newlen
		out = tab[divide] + out
	if out == "":
		out = "0"

	return out
	
func combine_bytes(bytes: Array):
	var number = ""
	var i = 0

	while i < bytes.size():
		var num = ""
		num = str(bytes[i])
		num = base_convert(num, 10, 16)
		number += num
		i += 1

	number = hex_to_dec(number)
	return number
	
func data_separate(val, start_index, _len, data = []):
	if data == []:
		data = Stats.game_data
		val = int(val)
	var combined = num_to_hex(val, _len * 2)
	for i in range(_len):
		data[start_index + i] = base_convert(combined.substr(i * 2, 2), 16, 10).to_int()
		
func data_combine(start_index, _len, data = []):
	if data.is_empty():
		data = Stats.game_data
	var arr = []
	for i in range(_len):
		arr.append(data[start_index + i])
	return combine_bytes(arr)
