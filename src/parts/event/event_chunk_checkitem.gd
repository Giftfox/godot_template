class_name CheckItemChunk
extends EventChunk

@export var item := Enums.Items.none
@export var value := 0
@export var new_step := -1
@export var is_equipped := false

enum check_types {equal, lesser, greater}
@export var check := check_types.greater

func _init(_item := Enums.Items.none, _value := 0, _new_step := -1, _check := check_types.greater, _is_equipped := false):
	item = _item
	value = _value
	new_step = _new_step
	check = _check
	is_equipped = _is_equipped
