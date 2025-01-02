class_name AddItemChunk
extends EventChunk

@export var item := Enums.Items.none
@export var quantity := 0

func _init(_item := Enums.Items.none, _q := 0):
	item = _item
	quantity = _q
