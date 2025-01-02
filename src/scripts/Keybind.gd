extends Node

enum action_modes {
	keyboard,
	controller
}
var last_action = action_modes.keyboard

enum gamepad_types {
	generic,
	playstation,
	nintendo_switch_pro
}
var gamepad_type = gamepad_types.generic

var binding_timer
var binding_action := ""
var binding_slot := 0
var input_buffer := false

var key_ids = [
	0, KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_A, KEY_A, KEY_A, KEY_A, KEY_A, KEY_A, KEY_A, KEY_B, KEY_C, KEY_D, KEY_E, KEY_F, KEY_G, KEY_H, KEY_I, KEY_J, KEY_K, KEY_L, KEY_M, KEY_N, KEY_O, KEY_P, KEY_Q, KEY_R, KEY_S, KEY_T, KEY_U, KEY_V, KEY_W, KEY_X, KEY_Y, KEY_Z,
	KEY_PERIOD, KEY_COMMA, KEY_SLASH, KEY_SPACE, KEY_BRACKETLEFT, KEY_BRACKETRIGHT, KEY_BACKSLASH, KEY_BACKSPACE, KEY_SEMICOLON, KEY_APOSTROPHE, KEY_SHIFT, KEY_CTRL
]
var button_ids = [
	0, JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER
]
var action_ids = ["menu_confirm", "menu_cancel"]

var keynames = {
	KEY_0: "0",
	KEY_1: "1",
	KEY_2: "2",
	KEY_3: "3",
	KEY_4: "4",
	KEY_5: "5",
	KEY_6: "6",
	KEY_7: "7",
	KEY_8: "8",
	KEY_9: "9",
	KEY_A: "A",
	KEY_B: "B",
	KEY_C: "C",
	KEY_D: "D",
	KEY_E: "E",
	KEY_F: "F",
	KEY_G: "G",
	KEY_H: "H",
	KEY_I: "I",
	KEY_J: "J",
	KEY_K: "K",
	KEY_L: "L",
	KEY_M: "M",
	KEY_N: "N",
	KEY_O: "O",
	KEY_P: "P",
	KEY_Q: "Q",
	KEY_R: "R",
	KEY_S: "S",
	KEY_T: "T",
	KEY_U: "U",
	KEY_V: "V",
	KEY_W: "W",
	KEY_X: "X",
	KEY_Y: "Y",
	KEY_Z: "Z",
	KEY_PERIOD: ".",
	KEY_COMMA: ",",
	KEY_SLASH: "/",
	KEY_SPACE: "Sp",
	KEY_BRACKETLEFT: "[",
	KEY_BRACKETRIGHT: "]",
	KEY_BACKSLASH: "\\",
	KEY_BACKSPACE: "Bak",
	KEY_SEMICOLON: ";",
	KEY_APOSTROPHE: "'",
	KEY_ESCAPE: "Esc",
	KEY_SHIFT: "Shift",
	KEY_CTRL: "Ctrl"
}

# Image types: xbox, ps, nintendo
var button_images = {
	# None
	-1: [15, 15, 15],
	# Reading
	-2: [14, 14, 14],
	
	# A
	JOY_BUTTON_A: [0, 2, 1],
	# B
	JOY_BUTTON_B: [1, 16, 0],
	# X
	JOY_BUTTON_X: [2, 17, 3],
	# Y
	JOY_BUTTON_Y: [3, 18, 2],
	# LB
	JOY_BUTTON_LEFT_SHOULDER: [5, 5, 5],
	# RB
	JOY_BUTTON_RIGHT_SHOULDER: [4, 4, 4],
	# LT
	#JOY_BUTTON_6: [7, 7, 7],
	# RT
	#JOY_BUTTON_7: [6, 6, 6],
	
	# Select
	JOY_BUTTON_GUIDE: [19, 23, 21],
	# Start
	JOY_BUTTON_START: [20, 24, 22],
	
	# Down
	JOY_BUTTON_DPAD_DOWN: [8, 8, 8],
	
	# Right analog up + down
	100: [10, 10, 10],
	101: [11, 11, 11]
}

signal keybind_completed()

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	
	binding_timer = Timer.new()
	binding_timer.process_mode = 0
	binding_timer.wait_time = 1.5
	binding_timer.one_shot = true
	binding_timer.process_mode = PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(binding_timer)
	
func _process(delta):
	input_buffer = false
	if is_binding() and binding_timer.is_stopped():
		binding_action = ""
		emit_signal("keybind_completed")
	
func get_keybind_name(keybind: String):
	var events = InputMap.action_get_events(keybind)
	var key_events = []
	var button_events = []
	for e in events:
		if e is InputEventKey:
			key_events.append(e)
		else:
			button_events.append(e)
			
	events = key_events
	if events.size() > 0:
		if keynames.has(events[0].keycode):
			return "[" + keynames[events[0].keycode] + "]"
		return "[?]"
	return "[]"
	
func is_binding():
	return binding_action != ""
	
func bind_key(action, slot = 0):
	binding_action = action
	binding_slot = slot
	binding_timer.start()
	input_buffer = true
	
func _input(event):
	if !input_buffer:
		var prev_action = last_action
		if event is InputEventKey and event.keycode != KEY_ESCAPE:
			last_action = action_modes.keyboard
		elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and abs(event.axis_value) > 0.5):
			last_action = action_modes.controller
			if Stats.game_settings[Stats.Settings.gamepad_type] == 0:
				gamepad_type = gamepad_types.generic
				for i in Input.get_connected_joypads():
					if "playstation" in Input.get_joy_name(i).to_lower():
						gamepad_type = gamepad_types.playstation
						break
					elif "switch" in Input.get_joy_name(i).to_lower():
						gamepad_type = gamepad_types.nintendo_switch_pro
						break
			else:
				gamepad_type = Stats.game_settings[Stats.Settings.gamepad_type] - 1
					
		#if last_action != prev_action and current_path.size() > 0:
		#	set_visuals(true)
			
		if binding_action != "":
			# Change keybind
			if (event is InputEventKey or event is InputEventJoypadButton) and event.pressed:
				if (event is InputEventKey and (key_ids.has(event.keycode) or event.keycode == KEY_ESCAPE)) \
				or (event is InputEventJoypadButton and (button_ids.has(event.button_index))):
					if event is InputEventWithModifiers:
						event.alt_pressed = false
						event.ctrl_pressed = false
						event.meta_pressed = false
						event.shift_pressed = false
					
					# Get current input events
					var events = InputMap.action_get_events(binding_action)
					var key_events = []
					var button_events = []
					for e in events:
						if e is InputEventKey:
							key_events.append(e)
						else:
							button_events.append(e)
					
					# Locate and change correct event
					if event is InputEventKey:
						events = key_events
					else:
						events = button_events
						
					if events.size() <= binding_slot:
						events.append(event)
					else:
						events[binding_slot] = event
						
					if Input.is_action_just_pressed("ui_clearkey"):
						events.remove(binding_slot)
						
					# Replace events in action
					InputMap.action_erase_events(binding_action)
					for e in key_events:
						InputMap.action_add_event(binding_action, e)
					for e in button_events:
						InputMap.action_add_event(binding_action, e)
						
					for i in range(2):
						if key_events.size() > i:
							Stats.game_settings[Stats.Settings.keybinds + 4 * action_ids.find(binding_action) + i] = key_ids.find(key_events[i].keycode)
						else:
							Stats.game_settings[Stats.Settings.keybinds + 4 * action_ids.find(binding_action) + i] = 255
					for i in range(2):
						if button_events.size() > i:
							Stats.game_settings[Stats.Settings.keybinds + 4 * action_ids.find(binding_action) + i + 2] = button_ids.find(button_events[i].button_index)
						else:
							Stats.game_settings[Stats.Settings.keybinds + 4 * action_ids.find(binding_action) + i + 2] = 255
							
					DataManager.settings_save()
					
					binding_action = ""
					emit_signal("keybind_completed")
					binding_timer.stop()
