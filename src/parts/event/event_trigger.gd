class_name EventTrigger
extends Area2D

@export var attached_event := 0
@export var trigger_on_step := true
@export var trigger_on_interact := false
@export var interact_distance := 1
@export var interact_up_extra := false
@export var pre_transition := false
@export var delete_flag := Enums.Flags.none
var entity_id := 0

var buffer_collision := 0
var queue_trigger := false
var can_interact := false

var space_state
		
func _ready():
	if delete_flag != Enums.Flags.none and Stats.get_flag(delete_flag) > 0:
		queue_free()
		
func _process(delta):
	if buffer_collision == 2:
		if Global.get_player().get_node("Movement").moving_direction != Vector2.ZERO:
			buffer_collision = 1
	elif buffer_collision == 1:
		if Global.get_player().get_node("Movement").moving_direction == Vector2.ZERO:
			buffer_collision = 0
	
	if Global.current_pausestate == Global.PauseState.NORMAL or (pre_transition and Global.current_pausestate == Global.PauseState.TRANSITION):
		if trigger_on_interact and Input.is_action_just_pressed("game_interact"):
			if interact_up_extra and can_interact:
				run_trigger_event()
			else:
				space_state = get_world_2d().direct_space_state
				var params = PhysicsRayQueryParameters2D.new()
				params.collide_with_areas = true
				params.from = global_position
				var dist = 1
				if interact_up_extra and Global.get_player().get_node("Movement").facing == Global.Dirs.UP:
					dist = 2
				dist = max(dist, interact_distance)
				params.to = params.from + Global.dir2vector(Global.opposite_dir(Global.get_player().get_node("Movement").facing)) * Global.TILE_SIZE * dist
				params.collision_mask = collision_mask
				var coll = space_state.intersect_ray(params)
				if coll and coll.collider.is_in_group("player"):
					run_trigger_event()
			
		if queue_trigger:
			if Global.get_player().get_node("Movement").moving_direction == Vector2.ZERO:
				queue_trigger = false
				run_trigger_event()
		
func run_trigger_event():
	if attached_event != 0:
		if get_parent().is_in_group("entity") and get_parent().turn_when_interacted:
			get_parent().face_entity(Global.get_player())
		Event.run_event(attached_event, self)

func _on_interact_square_area_entered(area):
	can_interact = true

func _on_interact_square_area_exited(area):
	can_interact = false


func _on_body_entered(body):
	if buffer_collision == 0 and body.is_in_group("player") and trigger_on_step:
		run_trigger_event()

func _on_body_exited(body):
	buffer_collision = 0
