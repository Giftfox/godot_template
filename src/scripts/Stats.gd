extends Node

enum Settings {
	screen_size,
	show_fps,
	master_vol,
	music_vol,
	sfx_vol,
	default_file,
	gamepad_type,
	vibration,
	fps_cap,
	
	accessibility = 20,
	no_shake,
	filter,
	visual_fx,
	clock,
	flashing,
	
	keybinds = 40,
	keybinds_end = 80,
	
	movement_type = 90,
	disable_stick,
	
	length = 150
}

enum Data {
	valid,
	version,
	utime,
	
	flags = 3000,
}

signal screen_set()

const data_version = 0
var file_slot := 0

var default_data := {
	Data.valid: false,
	Data.version: data_version,
	Data.utime: 0,
	
	Data.flags: []
}
var game_data := {}
var game_settings := []

var player_direction := Global.Dirs.DOWN

func _ready():
	data_load()
	DataManager.settings_load()
	DataManager.window_load()
	
	process_mode = PROCESS_MODE_ALWAYS

func set_flag(flag, ind = 1):
	game_data[Data.flags][flag] = ind
	
func get_flag(flag):
	if !game_data[Data.flags].has(flag):
		return 0
	return game_data[Data.flags][flag]

func initialize_data():
	game_data.clear()
	game_data = default_data.duplicate()
	
	game_data[Data.version] = data_version
	game_data[Data.utime] = floor(Time.get_unix_time_from_system())
	
func data_save(slot = -1):
	if slot == -1:
		slot = file_slot
	DataManager.data_save(slot)
	
func data_load(slot = -1):
	if slot == -1:
		slot = file_slot
	DataManager.data_load(slot)
	
func initialize_settings():
	game_settings.clear()
	while game_settings.size() < 100:
		game_settings.append(0)
		
	game_settings[Settings.screen_size] = 1
	game_settings[Settings.music_vol] = 8
	game_settings[Settings.sfx_vol] = 8
	
	initialize_keybinds()
	set_all_settings()
	
func initialize_keybinds():
	set_keybind("menu_confirm", [KEY_Z, KEY_SPACE, 0, 0])
	set_keybind("menu_cancel", [KEY_X, KEY_BACKSPACE, 0, 0])

func set_setting(setting, val = null, set_in_data = true):
	if val != null and set_in_data:
		game_settings[setting] = val
	if !val:
		val = game_settings[setting]
	
	match setting:
		Settings.screen_size:
			const _range = Vector2i(1, 3)
			const start = 1.0
			const step = 0.5
			
			if game_settings[Settings.screen_size] >= _range.y:
				DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
				var wsize = DisplayServer.window_get_size()
				var stretch = start + step * (game_settings[Settings.screen_size] - 1)
				var newsize = Vector2i(stretch * Global.VIEW_SIZE.x * Global.VIEW_SCALE, stretch * Global.VIEW_SIZE.y * Global.VIEW_SCALE)
				DisplayServer.window_set_size(newsize)
				
				var diff = wsize - newsize
				var newpos = DisplayServer.window_get_position() + diff / 2
				newpos.y = max(newpos.y, 30)
				DisplayServer.window_set_position(newpos)
				
			emit_signal("screen_set")
			
		Settings.master_vol:
			set_volume(AudioServer.get_bus_index("Master"), val)
		Settings.music_vol:
			set_volume(AudioServer.get_bus_index("Music"), val)
		Settings.sfx_vol:
			set_volume(AudioServer.get_bus_index("SFX"), val)
			
		Settings.keybinds:
			var i = 0
			while i < Settings.keybinds_end and floor(i / 4) < Keybind.action_ids.size():
				var keylist = []
				for j in range(4):
					if j < 2:
						keylist.append(Keybind.key_ids[game_settings[Settings.keybinds + i + j]])
					else:
						keylist.append(Keybind.button_ids[game_settings[Settings.keybinds + i + j]])
				set_keybind(Keybind.action_ids[floor(i / 4)], keylist)
				i += 4
				

func set_keybind(action_id, keys = []):
	var events = InputMap.action_get_events(action_id)
	
	events.clear()
	for i in range(2):
		if keys[i] != 0:
			var e = InputEventKey.new()
			e.keycode = keys[i]
			events.append(e)
		game_settings[Settings.keybinds + Keybind.action_ids.find(action_id) * 4 + i] = Keybind.key_ids.find(keys[i])
	
	# Replace events in action
	InputMap.action_erase_events(action_id)
	for e in events:
		InputMap.action_add_event(action_id, e)

func set_volume(bus, volume):
	var amp = float(volume) / 10.0
	amp = Global.scale_range_to(amp, 0.000001, 1)
	var db = (log(amp) / log(10)) * 20

	AudioServer.set_bus_volume_db(bus, db)
	AudioServer.set_bus_mute(bus, volume == 0)

func set_all_settings():
	var i = 0
	for s in game_settings:
		set_setting(i)
		i += 1

func add_stat(stat: Data, val: int):
	if !game_data.keys().has(stat):
		game_data[stat] = default_data[stat]
	game_data[stat] += val

func set_stat(stat: Data, val):
	game_data[stat] = val
	
func get_stat(stat: Data):
	if !game_data.keys().has(stat):
		game_data[stat] = default_data[stat]
	return game_data[stat]
