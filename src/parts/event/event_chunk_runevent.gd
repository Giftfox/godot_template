class_name RunEventChunk
extends EventChunk

@export var event_id_common := Event.Common.none
@export var event_id := -1
@export var module_id := -1
@export var module_step := 0

func _init(_id := -1, _module_id := -1, _module_step := 0):
	event_id = _id
	module_id = _module_id
	module_step = _module_step
