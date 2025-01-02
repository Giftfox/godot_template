class_name DialogueChunk
extends EventChunk

var dialogue_lines : Array[String]
@export var localized_strings : Array[LocalizedString]
@export var portrait := DialoguePortrait.portraits.none
@export var portrait_on_left := false
@export var choice_result_step : Array[int]
@export var choice_result_event : Array[int]
@export var choice_header := ""
@export var is_choice := false

func _init(lines : Array[String] = [], _portrait = DialoguePortrait.portraits.none, _portrait_on_left = false, result_steps : Array[int] = [], result_events : Array[int] = [], header = "", _is_choice = false):
	dialogue_lines = lines
	portrait = _portrait
	portrait_on_left = _portrait_on_left
	choice_result_step = result_steps
	choice_result_event = result_events
	choice_header = header
	is_choice = _is_choice

func get_all_text():
	var lines = []
	for line in dialogue_lines:
		lines.append(Global.loc(line))
	for line in localized_strings:
		lines.append(line.get_text())
	return lines
