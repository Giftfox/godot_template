class_name SFX
extends AudioStreamPlayer

var sounds := {
	"": null
}
var current_id := ""

func play_sfx(id = "") -> void:
	if sounds.has(id):
		var sfx = sounds[id]
		if sfx and (!sfx_priority() or sfx_priority(id)):
			if playing:
				stop()
			stream = sfx
			play()
		
func sfx_priority(id = "") -> bool:
	if id == "":
		id = current_id
		if !playing:
			return false
	return false
