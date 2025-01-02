class_name CheckQuestChunk
extends EventChunk

@export var flag := Enums.Flags.none
@export var event_step := -1

func _init(_flag = Enums.Flags.none, _event_step = -1):
	flag = _flag
	event_step = _event_step
