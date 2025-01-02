class_name DialoguePortrait
extends Node2D

enum portraits {
	none,
	
	player,
	
	silver,
	shroomfox,
	whitewitch,
	sheepwitch,
	zack,
	bianca,
	rytha
}
var portrait := portraits.none

var portrait_textures = {
	
}

func prepare():
	$Base.texture = null
	$Base.material = $Base.material.duplicate()
	$PlayerGear/Hair.texture = null
	$PlayerGear/Face.texture = null
	if portrait_textures.keys().has(portrait):
		$Base.texture = portrait_textures[portrait]
	$PlayerGear.visible = false
		
func _process(delta):
	pass
