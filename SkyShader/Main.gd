extends Node3D

var anim_player: AnimationPlayer

func _ready() -> void:
	anim_player = get_node("AnimationPlayer")
	
	if anim_player:
		anim_player.play("sunriseset")
