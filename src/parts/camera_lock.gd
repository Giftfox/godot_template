class_name CameraLock
extends Area2D

@export var full_lock := false
@export var global := false
@export var roam_outside := false
@export var automatic := false

var has_player := false
var transitioning := -1.0
var transition_start := Vector2.ZERO
var transition_player_start := Vector2.ZERO
var transition_player_end := Vector2.ZERO

func _ready():
	if global:
		has_player = true
		lock()

func _physics_process(delta):
	if transitioning >= 0.0:
		transitioning = Global.approach_value(transitioning, 1.0, 0.03 * delta * 60)
		var cam = Global.get_camera()
		cam.current_pos = transition_start + (cam.target_pos - transition_start) * transitioning
		cam.camera_finalize()
		
		Global.get_player().global_position = transition_player_start + (transition_player_end - transition_player_start) * transitioning
		Global.get_player().get_node("Shadow").visible = false
		
		if transitioning == 1.0:
			transitioning = -1.0
			transition_start = Vector2.ZERO
			Global.get_player().get_node("Shadow").visible = true
			cam.override = false
			Global.current_chunk_control.activate_chunk()

func lock(on = true):
	var cam = Global.get_camera()
	
	if on:
		var boundary = Rect2(Vector2(-100000, -100000), Vector2(1000000, 1000000))
		boundary.position.x = max(boundary.position.x, $CollisionShape2D.global_position.x - $CollisionShape2D.shape.size.x / 2)
		boundary.position.y = max(boundary.position.y, $CollisionShape2D.global_position.y - $CollisionShape2D.shape.size.y / 2)
		boundary.end.x = min(boundary.end.x, $CollisionShape2D.global_position.x + $CollisionShape2D.shape.size.x / 2)
		boundary.end.y = min(boundary.end.y, $CollisionShape2D.global_position.y + $CollisionShape2D.shape.size.y / 2)
		for t in get_tree().get_nodes_in_group("autospawn_tiles"):
			t.spawn_tiles(self, boundary)
	
	if full_lock:
		if on:
			cam.pos_override = global_position
		elif cam.pos_override == global_position:
			cam.pos_override = Vector2.ZERO
	else:
		if on:
			cam.boundary_area = self
			cam.boundary_shape = $CollisionShape2D
		elif cam.boundary_area == self:
			cam.boundary_area = null
			cam.boundary_shape = null

func transition():
	transitioning = 0.0
	var cam = Global.get_camera()
	cam.override = true
	lock()
	transition_start = cam.current_pos
	cam.find_position()
	
	var player = Global.get_player()
	transition_player_start = player.global_position
	
	var coll = player.get_node("TransitionBox/CollisionShape2D")
	var prect = coll.shape.get_rect()
	prect.position += coll.global_position
	prect.position.y -= player.z_height
	
	var crect = $CollisionShape2D.shape.get_rect()
	crect.position += $CollisionShape2D.global_position + Vector2(3, 3)
	crect.size -= Vector2(6, 6)
	
	var offset_pos := Vector2.ZERO
	while !crect.encloses(prect):
		var shift = Vector2.ZERO
		if prect.position.x < crect.position.x:
			shift.x = 1
		if prect.end.x > crect.end.x:
			shift.x = -1
		if prect.position.y < crect.position.y:
			shift.y = 1
		if prect.end.y > crect.end.y:
			shift.y = -1
			
		offset_pos += shift
		prect.position += shift
	
	transition_player_end = transition_player_start + offset_pos

func queue_free():
	_on_area_exited(Global.get_player())
	super.queue_free()

func _on_area_entered(area):
	if area.is_in_group("player"):
		has_player = true
		if !global and automatic:
			lock()

func _on_area_exited(area):
	if area.is_in_group("player"):
		has_player = false
		if !global and roam_outside and automatic:
			lock(false)

func _on_body_entered(body):
	_on_area_entered(body)

func _on_body_exited(body):
	_on_area_exited(body)

func rect_enclosed(rect):
	return get_rect().encloses(rect)

func point_contained(point):
	return get_rect().has_point(point)

func get_rect():
	var crect = $CollisionShape2D.shape.get_rect()
	crect.position += $CollisionShape2D.global_position
	return crect
