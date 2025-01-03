class_name TrackingArea2D
extends Area2D

@export var intersecting_groups_whitelist : Array[String] = []
var intersecting_entities := []

func _ready():
	area_entered.connect(on_area_entered)
	area_exited.connect(on_area_exited)
	
func on_area_entered(area):
	if !intersecting_entities.has(area):
		var valid = true
		if !intersecting_groups_whitelist.is_empty():
			valid = false
			for group in intersecting_groups_whitelist:
				if area.is_in_group(group):
					valid = true
					break
		
		if valid:
			intersecting_entities.append(area)
	
func on_area_exited(area):
	if intersecting_entities.has(area):
		intersecting_entities.erase(area)
