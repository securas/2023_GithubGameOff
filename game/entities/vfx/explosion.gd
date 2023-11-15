class_name Explosion extends Sprite2D

func explode() -> void:
	rotation = randf() * TAU
	$anim.play( "explode" )
	$anim.queue( "RESET" )

