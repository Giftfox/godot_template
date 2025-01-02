extends Node

const TILE_SIZE = 24
const VIEW_SIZE = Vector2(480, 270)
const VIEW_SCALE = 2
const ADJACENTS = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]

enum PauseState {
	NORMAL,
	PAUSED,
	TRANSITION,
	EVENT,
	DEFEAT,
	HITLAG
}

var hitlag_time := -1.0
var current_pausestate = PauseState.NORMAL
var old_pausestate = PauseState.NORMAL
var entity_active = true

var player_x := 0
var player_y := 0
var player_x_offset := 0
var player_y_offset := 0

var mouse_pos := Vector2.ZERO

var database_script = preload("res://src/scripts/Database.gd")
@onready var database = database_script.new()
var localization_storage = []

# flag values stolen shamelessly from BYOND
enum Dirs {
	UP = 1,
	DOWN = 2,
	RIGHT = 4,
	LEFT = 8,
}
enum Diags {
	UP_RIGHT = Dirs.UP|Dirs.RIGHT,
	UP_LEFT = Dirs.UP|Dirs.LEFT,
	DOWN_RIGHT = Dirs.DOWN|Dirs.RIGHT,
	DOWN_LEFT = Dirs.DOWN|Dirs.LEFT,
}

# used for iteration, exports, etc
enum AllDirs {
	UP = Dirs.UP,
	DOWN = Dirs.DOWN,
	RIGHT = Dirs.RIGHT,
	LEFT = Dirs.LEFT,
	UP_RIGHT = Diags.UP_RIGHT,
	UP_LEFT = Diags.UP_LEFT,
	DOWN_RIGHT = Diags.DOWN_RIGHT,
	DOWN_LEFT = Diags.DOWN_LEFT,
}
enum HDirs {
	RIGHT = Dirs.RIGHT,
	LEFT = Dirs.LEFT,
}
enum VDirs {
	UP = Dirs.UP,
	DOWN = Dirs.DOWN,
}

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	
func _physics_process(delta):
	if hitlag_time > -1:
		hitlag_time -= 1 * delta * 60
		if hitlag_time <= 0:
			hitlag_time = -1
			set_pause_state(old_pausestate, true)
	mouse_pos = get_viewport().get_mouse_position()
			
func vec_scale_x_to(v: Vector2, x: float) -> Vector2:
	v = v.normalized()
	v /= v.x
	return v * x

func vec_scale_y_to(v: Vector2, y: float) -> Vector2:
	v = v.normalized()
	v /= v.y
	return v * y
	
func scale_range_to(x: float, y_min: float, y_max: float) -> float:
	return y_min*(1-x) + y_max*x
	
func vector2dir(v: Vector2, diagonals := false) -> int:
	v.y *= -1 # flip over x axis to match real world angles
	
	var dir = Dirs.DOWN
	var angle_step = (PI/4 if diagonals else PI/2)/2
	
	if abs(v.angle_to(rad2vector(0))) < angle_step:
		dir = Dirs.RIGHT
	if abs(v.angle_to(rad2vector(PI/2))) < angle_step:
		dir = Dirs.UP
	if abs(v.angle_to(rad2vector(PI))) < angle_step:
		dir = Dirs.LEFT
	if abs(v.angle_to(rad2vector(PI*3/2))) < angle_step:
		dir = Dirs.DOWN
	
	if dir == 0 or diagonals:
		if abs(v.angle_to(rad2vector(PI/4))) < PI/4:
			dir = Diags.UP_RIGHT
		if abs(v.angle_to(rad2vector(PI*3/4))) < PI/4:
			dir = Diags.UP_LEFT
		if abs(v.angle_to(rad2vector(PI*5/4))) < PI/4:
			dir = Diags.DOWN_LEFT
		if abs(v.angle_to(rad2vector(PI*7/4))) < PI/4:
			dir = Diags.DOWN_RIGHT
		
		if !diagonals:
			match dir:
				Diags.UP_RIGHT:
					dir = Dirs.RIGHT
				Diags.UP_LEFT:
					dir = Dirs.LEFT
				Diags.DOWN_RIGHT:
					dir = Dirs.RIGHT
				Diags.DOWN_LEFT:
					dir = Dirs.LEFT

	if not dir: push_error("no dir")
	return dir

func dir2vector(dir):
	var vec = Vector2.ZERO
	match dir:
		Dirs.LEFT:
			vec = Vector2(-1, 0)
		Dirs.RIGHT:
			vec = Vector2(1, 0)
		Dirs.UP:
			vec = Vector2(0, -1)
		Dirs.DOWN:
			vec = Vector2(0, 1)
	return vec
	
func polar2cartesian(rad, angle):
	var x = rad * cos(angle)
	var y = rad * sin(angle)
	return Vector2(x, y)
	
func rad2vector(angle) -> Vector2:
	return polar2cartesian(1, angle)

#func deg2vector(angle) -> Vector2:
#	return rad2vector(deg2rad(angle))
			
func get_dir(from: Vector2, to: Vector2, diagonals: bool = true) -> int:
	return vector2dir(rad2vector(from.angle_to_point(to)), diagonals)
	
func get_cardinal(from: Vector2, to: Vector2) -> int:
	return get_dir(from, to, false)
	
func get_diagonal(from: Vector2, to: Vector2) -> int:
	var dir = get_dir(from, to)
	match dir:
		Dirs.UP:
			if to.x < from.x:
				dir = Diags.UP_LEFT
			else:
				dir = Diags.UP_RIGHT
		Dirs.DOWN:
			if to.x < from.x:
				dir = Diags.DOWN_LEFT
			else:
				dir = Diags.DOWN_RIGHT
		Dirs.LEFT:
			if to.y < from.y:
				dir = Diags.UP_LEFT
			else:
				dir = Diags.DOWN_LEFT
		Dirs.RIGHT:
			if to.y < from.y:
				dir = Diags.UP_RIGHT
			else:
				dir = Diags.DOWN_RIGHT
	return dir
	# asdfasdf

func opposite_dir(dir) -> int:
	var new_dir = 0
	match dir:
		Dirs.LEFT:
			new_dir = Dirs.RIGHT
		Dirs.RIGHT:
			new_dir = Dirs.LEFT
		Dirs.UP:
			new_dir = Dirs.DOWN
		Dirs.DOWN:
			new_dir = Dirs.UP
			
		Diags.UP_LEFT:
			new_dir = Diags.DOWN_RIGHT
		Diags.UP_RIGHT:
			new_dir = Diags.DOWN_LEFT
		Diags.DOWN_LEFT:
			new_dir = Diags.UP_RIGHT
		Diags.DOWN_RIGHT:
			new_dir = Diags.UP_LEFT
			
	return new_dir
	
func distance_to_vector(from: Vector2, to: Vector2, diagonal_equal := false) -> float:
	var dist = 0
	dist += abs(from.x - to.x)
	if diagonal_equal:
		dist = max(dist, abs(from.y - to.y))
	else:
		dist += abs(from.y - to.y)
	return dist
	
func approach_value(current: float, target: float, increase: float) -> float:
	if target != current:
		if sign(increase) == 1 and abs(target - current) < abs(increase):
			current = target
		else:
			if target < current:
				increase *= -1
			current += increase
		
	return current
	
func approach_vector(current: Vector2, target: Vector2, increase: float) -> Vector2:
	if target != current:
		current -= rad2vector(target.angle_to_point(current)) * increase
		if current.distance_to(target) < increase:
			current = target
			
	return current
	
func approach_vector_accel(current: Vector2, target: Vector2, increase: float, delta = 0, accel_threshold_mod = 8.0) -> Vector2:
	if target != current:
		var dist = current.distance_to(target)
		#var max_dist = origin.distance_to(target) * accel_threshold_mod
		var max_dist = increase * accel_threshold_mod
		var mod = 1.0
		if dist < max_dist:
			mod = dist / max_dist
		mod = max(mod, 0.1)
		
		var change = rad2vector(target.angle_to_point(current)) * increase * mod
		if delta != 0:
			change *= delta * 60
		current -= change
		if current.distance_to(target) < increase:
			current = target
		
	return current
	
func snap_vector(pos: Vector2):
	var cell_x = floor(pos.x / float(TILE_SIZE)) + 0.5
	var cell_y = floor(pos.y / float(TILE_SIZE)) + 0.5
	pos = Vector2(cell_x * TILE_SIZE, cell_y * TILE_SIZE)
	return pos
	
func get_cardinal_input(left = "menu_left", right = "menu_right", up = "menu_up", down = "menu_down"):
	var shift = Vector2.ZERO
	if Input.is_action_just_pressed(left):
		shift.x -= 1
	if Input.is_action_just_pressed(right):
		shift.x += 1
	if Input.is_action_just_pressed(up):
		shift.y -= 1
	if Input.is_action_just_pressed(down):
		shift.y += 1
	return shift
	
func shift_input(decrease_input, increase_input, buffered = false, buffer = 0.1):
	var shift = 0
	if buffered:
		if InputActions.is_action_buffered(decrease_input, buffer):
			shift -= 1
		if InputActions.is_action_buffered(increase_input, buffer):
			shift += 1
	else:
		if Input.is_action_just_pressed(decrease_input):
			shift -= 1
		if Input.is_action_just_pressed(increase_input):
			shift += 1
	return shift
	
func shift_index(current, minval, maxval, inc):
	current += inc
	if current > maxval:
		current = minval + (current - 1) - maxval
	if current < minval:
		current = maxval - minval - (abs(current) - 1)
		
	return current

func bytes_to_string(arr, start = -1, end = -1):
	if start == -1:
		start = 0
	if end == -1:
		end = arr.size() - 1
		
	var txt = ""
	for i in range(end - start):
		if arr[start + i] != 0:
			txt += char(arr[start + i])
		else:
			break
	return txt
	
func array_has_deep(arr, index, position = -999):
	for i in arr:
		if position == -999:
			return i.has(index)
		else:
			return i.size() > position and i[position] == index
	return false
	
func array_get_deep(arr, index, position = -999):
	var i = 0
	for a in arr:
		if position == -999:
			if a.has(index):
				return i
		else:
			if a.size() > position and a[position] == index:
				return i
		i += 1
	return -1
	
func clamp_degrees(deg) -> float:
	return fposmod(deg, 360)
	
func number_to_text(num):
	var new_text = ""
	var text = str(num)
	for i in range(text.length()):
		var index = i + 1
		new_text = text[-index] + new_text
		if i != 0 and index % 3 == 0 and i < text.length() - 1:
			new_text = "," + new_text
	return new_text
	
func split_text_into_lines(text, line_width):
	var new_text = ""
	var word = ""
	var length = 0
	for ch in text:
		length += 1
		if ch != ' ':
			word += ch
		else:
			if length <= line_width:
				new_text += word + " "
			else:
				length = word.length() + 1
				new_text += "\n" + word + " "
			word = ""
	if word != "":
		if length <= line_width:
			new_text += word
		else:
			new_text += "\n" + word
			
	return new_text
	
func color_rich_text(text, col):
	return "[color=" + col + "]" + text + "[/color]"
	
func fr(text):
	var formatting = {
		#"input_game_interact": Keybind.get_keybind_name("game_interact"),
	}
	
	#if !Stats.game_data.is_empty():
	#	formatting["player_name"] = Stats.get_stat(Stats.Data.pname)
		
	return text.format(formatting)
	
func loc(key, text = ""):
	if OS.is_debug_build() and text != "":
		var fail = false
		for line in localization_storage:
			if line[0] == key:
				fail = true
				break
		
		if !fail:
			var file = DataManager.file_open("res://loc/localized_text.csv", FileAccess.READ_WRITE, true)
			
			var full_data = []
			var data = file.get_csv_line()
			if data[0] == "":
				full_data.append(PackedStringArray(["keys", "en"]))
			else:
				while !file.eof_reached():
					full_data.append(data)
					data = file.get_csv_line()
			
			var found = false
			var found_translated = false
			for line in full_data:
				if line[0] != "keys":
					if line[0] == key:
						line[1] = text
						found = true
						break
					if line[1] == key:
						found_translated = true
			if !found and !found_translated:
				full_data.append(PackedStringArray([key, text]))
			
			localization_storage = full_data
			
			var data_without_header = full_data.duplicate()
			data_without_header.remove_at(0)
			data_without_header.sort_custom(sort_localization)
			data_without_header.insert(0, full_data[0])
			file = DataManager.file_open("res://loc/localized_text.csv", FileAccess.WRITE, true)
			for line in data_without_header:
				file.store_csv_line(line)
				
			file = null
	
	#return "---"
	
	var new_text = tr(key)
	if new_text != key:
		return fr(new_text)
		
	for line in localization_storage:
		if line[0] == key:
			return fr(line[1])
			
	if text != "":
		return fr(text)
	return fr(key)
	
func count_localized_words():
	var length = 0
	var word = ""
	for line in localization_storage:
		for char in line[1]:
			if ![' ', '\n'].has(char):
				word += char
			else:
				length += 1
				word = ""
		if word != "":
			length += 1
			word = ""
	return length
	
func sort_localization(a, b):
	var pointer = 0
	var a_asc = a[0].to_ascii_buffer()
	var b_asc = b[0].to_ascii_buffer()
	while pointer < a_asc.size() and pointer < b_asc.size() and a_asc[pointer] == b_asc[pointer]:
		pointer += 1
		if pointer == a_asc.size():
			return true
		
	pointer = min(pointer, min(a_asc.size() - 1, b_asc.size() - 1))
	return a_asc[pointer] < b_asc[pointer]
	
func set_language(code = "en"):
	TranslationServer.set_locale(code)
	database = database_script.new()
	
func clear_object(obj):
	if !is_instance_valid(obj):
		return null
	return obj
	
func get_family(scene):
	var nodes := []
	for c in scene.get_children():
		if !c.get_children().is_empty():
			var extra_nodes = get_family(c)
			for n in extra_nodes:
				nodes.append(n)
		nodes.append(c)
	return nodes
	
func get_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		for p in players:
			if p.active:
				return p
		return players[0]
	return null
	
func set_hitlag(frames := 6.0):
	hitlag_time = max(frames, hitlag_time)
	set_pause_state(PauseState.HITLAG)
	
func get_camera():
	var cams = get_tree().get_nodes_in_group("camera")
	var cam = null
	for c in cams:
		if c.focus:
			cam = c
			break
	return cam
	
func get_m5x7_width(txt):
	var caps_letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
	var caps = [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 8, 6, 6, 6, 6, 6, 6, 6, 6, 6, 8, 6, 6, 6]
	var lower_letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
	var lower = [6, 6, 5, 6, 6, 5, 6, 6, 3, 4, 5, 3, 8, 6, 6, 6, 6, 5, 6, 5, 6, 6, 8, 6, 6, 6]
	var special_letters = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '(', ')', '<', '>', '{', '}', '-', '=', '_', '+', '!', '@', '#', '$', '%', '^', '&', '*', ',', '.', '/', '\'', ';', ':', '\"', '|']
	var special = [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 4, 4, 4, 4, 6, 5, 6, 6, 2, 6, 6, 6, 6, 6, 7, 4, 3, 2, 4, 2, 3, 2, 4, 2]
	var width = 0
	for ch in txt:
		if caps_letters.has(ch):
			width += caps[caps_letters.find(ch)]
		if lower_letters.has(ch):
			width += lower[lower_letters.find(ch)]
		if special_letters.has(ch):
			width += special[special_letters.find(ch)]
	return width


func set_pause_state(ps = PauseState.NORMAL, priority = false):
	if current_pausestate != PauseState.HITLAG or priority:
		if current_pausestate != ps:
			old_pausestate = current_pausestate
		current_pausestate = ps
	
		var tree = get_tree()
		
		tree.set_group_flags(2, "player", "process_mode", PROCESS_MODE_PAUSABLE)
		tree.set_group_flags(2, "view", "process_mode", PROCESS_MODE_PAUSABLE)
		tree.set_group_flags(2, "entity", "process_mode", PROCESS_MODE_PAUSABLE)
		tree.set_group_flags(2, "combatentity", "process_mode", PROCESS_MODE_PAUSABLE)
		tree.set_group_flags(2, "tile", "process_mode", PROCESS_MODE_PAUSABLE)
		tree.set_group_flags(2, "item", "process_mode", PROCESS_MODE_PAUSABLE)
		tree.set_group_flags(2, "event", "process_mode", PROCESS_MODE_PAUSABLE)
		
		tree.set_group_flags(2, "camera", "process_mode", PROCESS_MODE_ALWAYS)
		
		for e in get_tree().get_nodes_in_group("entity"):
			e.toggle_collision(true)
		
		match ps:
			PauseState.NORMAL:
				tree.paused = false
				entity_active = true
			PauseState.PAUSED:
				tree.set_group_flags(2, "views", "process_mode", PROCESS_MODE_PAUSABLE)
				tree.paused = true
				entity_active = false
			PauseState.TRANSITION:
				tree.set_group_flags(2, "view", "process_mode", PROCESS_MODE_ALWAYS)
				tree.set_group_flags(2, "player", "process_mode", PROCESS_MODE_ALWAYS)
				#tree.set_group_flags(2, "movement", "process_mode", PROCESS_MODE_PAUSABLE)
				tree.set_group_flags(2, "entity", "process_mode", PROCESS_MODE_ALWAYS)
				tree.set_group_flags(2, "event", "process_mode", PROCESS_MODE_ALWAYS)
				tree.set_group_flags(2, "tile", "process_mode", PROCESS_MODE_ALWAYS)
				tree.set_group_flags(2, "item", "process_mode", PROCESS_MODE_ALWAYS)
				
				#if Global.current_room_control.has_player:
				#	get_player().get_node("Movement").movement_input = Vector2.ZERO
				tree.paused = true
				entity_active = false
				PhysicsServer2D.set_active(true)
			PauseState.EVENT:
				tree.set_group_flags(2, "view", "process_mode", PROCESS_MODE_ALWAYS)
				tree.set_group_flags(2, "player", "process_mode", PROCESS_MODE_ALWAYS)
				tree.set_group_flags(2, "entity", "process_mode", PROCESS_MODE_ALWAYS)
				tree.set_group_flags(2, "event", "process_mode", PROCESS_MODE_ALWAYS)
				tree.set_group_flags(2, "tile", "process_mode", PROCESS_MODE_ALWAYS)
				tree.set_group_flags(2, "item", "process_mode", PROCESS_MODE_ALWAYS)
				
				if Global.current_room_control.has_player:
					get_player().get_node("Movement").movement_input = Vector2.ZERO
				for e in get_tree().get_nodes_in_group("entity"):
					e.toggle_collision(false)
				tree.paused = true
				entity_active = false
				PhysicsServer2D.set_active(true)
			PauseState.DEFEAT:
				tree.set_group_flags(2, "views", "process_mode", PROCESS_MODE_PAUSABLE)
				tree.set_group_flags(2, "player", "process_mode", PROCESS_MODE_ALWAYS)
				tree.paused = true
				entity_active = false
			PauseState.HITLAG:
				tree.set_group_flags(2, "view", "process_mode", PROCESS_MODE_PAUSABLE)
				tree.set_group_flags(2, "camera", "process_mode", PROCESS_MODE_PAUSABLE)
				tree.paused = true
				entity_active = false
				PhysicsServer2D.set_active(true)
