extends Node

enum Events {
	time_spent,
	save_game
}

var event_info := {}
var timer
var prepped := false
var caught_up := false
var ticks_left := 0

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	
	if !prepped:
		event_info.clear()
		for e in Events.values():
			event_info[e] = {"ticks": 0.0, "tick_max": 1.0, "catch_up": true}
			
		event_info[Events.save_game]["tick_max"] = 60.0
		event_info[Events.save_game]["catch_up"] = false
			
		timer = Timer.new()
		add_child(timer)
		timer.one_shot = false
		timer.autostart = true
		timer.wait_time = 0.1
		timer.start()
		timer.timeout.connect(self._on_timeout)
		
		prepped = true

func _process(delta):
	if Stats.get_stat(Stats.Data.utime) != 0 and (Stats.get_stat(Stats.Data.utime) > floor(Time.get_unix_time_from_system()) or Stats.get_stat(Stats.Data.utime) < floor(Time.get_unix_time_from_system()) - 1000000):
		caught_up = true
		Stats.set_stat(Stats.Data.utime, floor(Time.get_unix_time_from_system()))
		
	if !caught_up and Stats.game_data[Stats.Data.utime] != 0:
		if SceneManager.current_room:
			catch_up()

func catch_up():
	if !prepped:
		_ready()
		
	var old_time = float(Stats.get_stat(Stats.Data.utime))
	if old_time == 0:
		Stats.set_stat(Stats.Data.utime, floor(Time.get_unix_time_from_system()))
		
	for e in Events.values():
		if event_info[e]["catch_up"]:
			event_info[e]["ticks"] += floor(Time.get_unix_time_from_system()) - old_time
	perform_actions(true, false)
	old_time = floor(Time.get_unix_time_from_system())
		
	caught_up = true

func _on_timeout():
	if SceneManager.current_room and caught_up:
		perform_actions()
	
func perform_actions(fast = false, increment_ticks = true):
	Stats.set_stat(Stats.Data.utime, floor(Time.get_unix_time_from_system()))
	
	for e in Events.values():
		if increment_ticks:
			event_info[e]["ticks"] += timer.wait_time
			
		# Pre-tick-calculation checks go here
		match e:
			_:
				pass
		
		# Perform time event
		var activations = 0
		while event_info[e]["ticks"] >= event_info[e]["tick_max"]:
			var info = event_info[e]
			info["ticks"] -= event_info[e]["tick_max"]
			activations += 1
			
		#print(info["ticks"])
		match e:
			Events.save_game:
				if SceneManager.current_room and activations > 0:
					pass
					# Global.current_room.save()
