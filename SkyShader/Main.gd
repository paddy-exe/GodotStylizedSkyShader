extends Node3D

#@onready anim_player : AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var anim_player : AnimationPlayer = $AnimationPlayer
	
	if Input.is_action_just_pressed("play"):
		anim_player.play("sunriseset")
	
