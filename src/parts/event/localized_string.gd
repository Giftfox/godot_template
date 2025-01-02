class_name LocalizedString
extends Resource

@export var key := ""
@export_multiline var text := ""

func _init(_text = "", _key = ""):
	text = _text
	key = _key

func get_text():
	return Global.loc(key, text)
