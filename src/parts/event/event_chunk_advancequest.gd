class_name AdvanceQuestChunk
extends EventChunk

@export var flag := Enums.Flags.none

func _init(_flag = Enums.Flags.none):
	flag = _flag
