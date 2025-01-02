extends Node

var buffered_inputs := []
const buffer := 1.0
const input_tracking := ["menu_left", "menu_right", "menu_up", "menu_down", "game_left", "game_right", "game_up", "game_down", "menu_confirm", "game_interact"]

func _ready():
	self.set_process_mode(3)

func _process(delta):
	for input in input_tracking:
		if Input.is_action_just_pressed(input):
			var found = false
			for i in range(buffered_inputs.size()):
				if buffered_inputs[i][0] == input:
					found = true
					buffered_inputs[i][1] = buffer
					break
			if !found:
				buffered_inputs.append([input, buffer])
	for i in range(buffered_inputs.size()):
		buffered_inputs[i][1] -= 0.0167 * delta * 60
		#if buffered_inputs[i][1] <= 0.0:
		#	buffered_inputs.remove_at(i)
		#	i -= 1
			
func is_action_buffered(action: String, custom_buffer = 0.1, reverse = false, held = false) -> bool:
	if input_tracking.has(action):
		for b in buffered_inputs:
			if b[0] == action:
				if reverse and b[1] < custom_buffer and (!held or Input.is_action_pressed(action)):
					return true
				elif b[1] > buffer - custom_buffer:
					return true
				#if ((!reverse and b[1] > buffer - custom_buffer) or (reverse and b[1] < custom_buffer)) and (!held or Input.is_action_pressed(action)):
				#	return true
				break
	return Input.is_action_just_pressed(action)
