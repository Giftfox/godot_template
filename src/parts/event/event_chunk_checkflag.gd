class_name CheckFlagChunk
extends EventChunk

@export var flag := Enums.Flags.none
@export var value := 0
@export var new_step := -1

enum check_types {equal, lesser, greater}
@export var check := check_types.greater

func _init(_flag := Enums.Flags.none, _value := 0, _new_step := -1, _check := check_types.greater):
	flag = _flag
	value = _value
	new_step = _new_step
	check = _check
