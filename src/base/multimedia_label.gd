@tool

class_name MultimediaLabel
extends RichTextLabel

@export var true_text := ""

func _process(delta):
	text = Global.fr(true_text)
	fr()
	
func fr():
	# Add links to image files here that you want to use in labels
	# The key name represents the formatting code you will use in the true_text string to display the image
	# Ex: true_text = "{slime} hello hi" will replace the {slime} part with the actual image
	var image_frames = {
		# "slime": ["res://assets/entities/enemies/slime_icon.png", "res://assets/entities/enemies/slime_icon2.png"]
	}
	var formatting = {}
	
	for key in image_frames:
		var frame = get_animation_frame(image_frames[key].size() - 1)
		formatting[key] = "[img]" + image_frames[key][frame] + "[/img]"
	
	text = text.format(formatting)

func get_animation_frame(max: int):
	return int(floor(Time.get_unix_time_from_system() * 2.5)) % (max + 1)
