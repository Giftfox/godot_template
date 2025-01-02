class_name TileMapEX
extends TileMapLayer

@export var invisible := false

func _ready() -> void:
	if invisible:
		visible = false
