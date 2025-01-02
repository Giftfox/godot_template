class_name EventModule
extends Resource

@export var allow_flag := Enums.Flags.none
@export var disallow_flag := Enums.Flags.none
@export var value_range := Vector2i.ONE

@export var steps : Array[EventStep] = []

func _init(_steps : Array[EventStep] = []):
	steps = _steps

func is_event_available():
	if allow_flag == Enums.Flags.none or ((value_range.x == -1 or Stats.get_flag(allow_flag) >= value_range.x) and (value_range.y == -1 or Stats.get_flag(allow_flag) <= value_range.y)):
		if disallow_flag == Enums.Flags.none or ((value_range.x == -1 or Stats.get_flag(disallow_flag) < value_range.x) or (value_range.y == -1 or Stats.get_flag(disallow_flag) > value_range.y)):
			return true
	return false
