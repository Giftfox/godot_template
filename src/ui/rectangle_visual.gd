@tool

class_name RectangleVisual
extends Node2D

@export var size := Vector2(100, 100)
@export var color := Color(1.0, 1.0, 1.0)
@export var fill_color := Color(0.0, 0.0, 0.0, 0.0)
@export var thickness := 1
@export var horizontal_centered := false
@export var vertical_centered := false

func _draw():
	var rect = Rect2(Vector2.ZERO, size)
	if horizontal_centered:
		rect.position.x -= size.x / 2
	if vertical_centered:
		rect.position.y -= size.y / 2
		
	draw_rect(rect, fill_color)
	draw_box(rect, color, thickness)
	
func draw_box(_rect, _c, _t):
	draw_line(_rect.position + Vector2(_t / 2.0, 0), Vector2(_rect.position.x, _rect.end.y) + Vector2(_t / 2.0, 0), _c, _t)
	draw_line(_rect.position + Vector2(0, _t / 2.0), Vector2(_rect.end.x, _rect.position.y) + Vector2(0, _t / 2.0), _c, _t)
	draw_line(Vector2(_rect.end.x, _rect.position.y) - Vector2(_t / 2.0, 0), _rect.end - Vector2(_t / 2.0, 0), _c, _t)
	draw_line(Vector2(_rect.position.x, _rect.end.y) - Vector2(0, _t / 2.0), _rect.end - Vector2(0, _t / 2.0), _c, _t)
	
func _process(delta):
	queue_redraw()
