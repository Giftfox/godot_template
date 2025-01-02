extends Node

var current_event := 0
var current_local_event := false
var current_source
var current_vars

var stored_event := 0
var stored_local_event := false
var stored_source
var stored_vars
var stored_step := 0

var dialogue_handler

var step := 0
var ending_step := 0
var first_frame := true
var step_advance := false

var room_changed := false

enum Common {
	none = 0,
	
	dialogue = 1
}

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	
func _process(delta):
	if current_event != 0:
		run_event(current_event, current_source, false, current_vars, current_local_event)
	else:
		step = 0
		step_advance = false
		room_changed = false
		first_frame = true
	
func store_event():
	if current_event != 0:
		stored_event = current_event
		stored_local_event = current_local_event
		stored_source = current_source
		stored_vars = current_source
		stored_step = step
	
func end_event(set_state = true, activate_trigger = true):
	if activate_trigger and current_source is EventTrigger and current_source.module_step():
		pass
	else:
		if set_state:
			if Global.current_pausestate == Global.PauseState.EVENT:
				var newstate = Global.PauseState.NORMAL
				if current_vars.keys().has("endstate"):
					newstate = current_vars["endstate"]
				Global.set_pause_state(newstate)
			dialogue_handler.end_dialogue()
			
		ending_step = step
		
		if stored_event != 0:
			current_event = stored_event
			current_local_event = stored_local_event
			current_source = stored_source
			current_vars = stored_vars
			step = stored_step
		else:
			current_event = 0
			current_local_event = false
			current_vars = null
			step = 0
			
			stored_event = 0
			stored_local_event = false
			stored_vars = null
			stored_step = 0
			
		step_advance = false
		room_changed = false
		first_frame = true
		
func run_event(event, source = null, override = false, vars = {}, local = false):
	if event == 0:
		return false
	
	if current_event != 0 and current_event != event and !override:
		return false
		
	var event_check = event
	if local != current_local_event:
		event_check = -1
		
	if current_event == event_check:
		first_frame = false
	else:
		first_frame = true
		stored_step += 1
		step = 0
		step_advance = false
		stored_local_event = current_local_event
		
	if override:
		first_frame = true
		step = 0
		step_advance = false
		
	var timer = SceneManager.game_view.get_node("EventTimer")
	if step_advance and timer.is_stopped():
		step += 1
		step_advance = false
		first_frame = true
	
	#var player
	#if Global.get_player():
	#	player = Global.get_player().get_node("EventHandler")
		
	current_event = event
	current_source = source
	current_vars = vars
	current_local_event = local
	
	if current_local_event:
		current_source.run_event(current_event)
		return
		
	match event:
		Common.dialogue:
			if !check_var("dialogue"):
				end_event()
			else:
				if !step_advance:
					if step < vars["dialogue"].size():
						if first_frame:
							if step == 0:
								Global.set_pause_state(Global.PauseState.EVENT)
							dialogue_handler.call_deferred("update_dialogue", vars["dialogue"][step].duplicate())
						else:
							var choice_dialogue = false
							for line in vars["dialogue"][step]:
								if line.is_choice:
									choice_dialogue = true
									break
							if !choice_dialogue and !dialogue_handler.active:
								if check_var("follow_event"):
									var follow_local = false
									if check_var("follow_local"):
										follow_local = vars["follow_local"]
									dialogue_handler.end_dialogue()
									run_event(vars["follow_event"], current_source, true, {}, follow_local)
								else:
									end_event()
									
		100:
			run_event(Common.dialogue, current_source, true, {"endstate": Global.PauseState.PAUSED, "dialogue": [[DialogueChunk.new([Global.loc("ITEM_CAMPSITE_UNAVAILABLE", "You can't set up a campsite here.")], DialoguePortrait.portraits.none, true)]]})
		
		_:
			return false
	return true

func advance():
	step_advance = true

func check_var(key):
	return current_vars and current_vars.keys().has(key)

func set_step(s):
	step = s - 1
	step_advance = true
	SceneManager.game_view.get_node("EventTimer").stop()

func get_npc(id):
	for e in get_tree().get_nodes_in_group("entity"):
		if e.npc_id == id:
			return e.get_node("EventHandler")
	print("NPC not found!")
	return null
