class_name SetFlagChunk
extends EventChunk

@export var flag := Enums.Flags.none
@export var value := 0
@export var add_value := false

func _init(_flag := Enums.Flags.none, _value := 0, _add_value := false):
	flag = _flag
	value = _value
	add_value = _add_value
