class_name EventStep
extends Resource

@export var chunks : Array[EventChunk]

func _init(_chunks : Array[EventChunk] = []):
	chunks = _chunks
