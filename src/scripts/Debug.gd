extends Node

var debug := false

func _ready():
	debug = OS.is_debug_build()
	
func _process(delta: float) -> void:
	if debug:
		if Input.is_action_just_pressed("system_scale"):
			Stats.set_setting(Stats.Settings.screen_size, Global.shift_index(Stats.game_settings[Stats.Settings.screen_size], 1, 3, 1), true)
			DataManager.settings_save()
