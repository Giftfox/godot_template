extends Node2D

var track_resource = preload("res://src/scenes/main/global_music_track.tscn")

var fade_ratio := -1.0
var queue_maintain := false

func _process(delta):
	if fade_ratio != -1.0:
		var playing = false
		for c in get_children():
			if c.stream and c.playing:
				playing = true
				break
				
		if playing:
			fade_ratio -= 0.01 * delta * 60
			if fade_ratio > 0.0:
				Stats.set_setting(Stats.Settings.music_vol, Stats.game_settings[Stats.Settings.music_vol] * fade_ratio, false)
			else:
				stop_track()
		else:
			fade_ratio = -1.0

func play_track(stream, from_start = true, volume_db = 0, pitch_scale = 1):
	# Reset fade volume
	Stats.set_setting(Stats.Settings.music_vol)
	fade_ratio = -1.0
	
	if stream:
		var found = false
		for c in get_children():
			if c.stream and c.stream.data == stream.data:
				c.volume_db = volume_db
				c.pitch_scale = pitch_scale
				if c.stream_paused:
					if from_start:
						c.play()
						c.awaiting = false
					else:
						c.stream_paused = false
						c.awaiting = false
				found = true
				break
		if !found:
			var track = track_resource.instance()
			add_child(track)
			track.stream = stream
			track.volume_db = volume_db
			track.pitch_scale = pitch_scale
			track.play()
	else:
		stop_track()
	
func stop_track(clear = true, exceptions = []):
	# Reset fade volume
	Stats.set_setting(Stats.Settings.music_vol)
	fade_ratio = -1.0
	
	if queue_maintain:
		clear = false
		queue_maintain = false
	
	for c in get_children():
		if c.stream and c.playing and !c.awaiting and !exceptions.has(c.stream.data):
			if clear:
				c.queue_free()
			else:
				c.stream_paused = true
				c.awaiting = true

func fadeout():
	fade_ratio = 1.0

func set_db(db):
	for c in get_children():
		if c.stream and c.playing:
			c.volume_db = db
