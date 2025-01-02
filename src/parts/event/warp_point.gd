class_name WarpPoint
extends EventTrigger

# For reference, "entrance" represents entering a map,
# while "exit" represents exiting a map
@export var is_entrance := true
@export var is_exit := true
@export var move_after_entering := true
@export var enter_direction := Global.Dirs.UP

@export var linked_map := ""
@export var linked_entrance := ""
@export var entrance_name := ""

var buffer_exit := false

func _ready():
	if is_entrance:
		add_to_group("warp_entrance")
	if is_exit:
		add_to_group("warp_exit")
		
func run_trigger_event():
	SceneManager.new_room_entrance = linked_entrance
	SceneManager.current_room_control.room_change(linked_map, true)
		
func move_player():
	buffer_collision = 2
	var off := Vector2.ZERO
	Global.get_player().global_position = global_position + off

func _on_body_entered(body):
	if is_exit and !buffer_exit:
		super._on_body_entered(body)

func _on_body_exited(body):
	buffer_exit = false
	super._on_body_exited(body)
