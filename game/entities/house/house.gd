extends Node2DPassiveEntity

var anim_nxt := "forward"
var anim_cur = ""

func _entity_activate( a : bool ) -> void:
	set_physics_process( a )
	$detect_player/player_collision.disabled = game.is_event( "received hat" )
	

func _physics_process( _delta : float ) -> void:
	if not owner or not owner.player: return
	if anim_cur != anim_nxt:
		anim_cur = anim_nxt
		$grand/anim.play( anim_cur )
	
	var dist = owner.player.global_position.x - $grand.global_position.x
	if dist > 2:
		anim_nxt = "forward"
	elif dist < -2:
		anim_nxt = "backward"
	


func _on_detect_player_body_entered( _body : Node2D ) -> void:
	game.state.has_hat = true
	owner.player._has_hat = true
	var _ret = game.add_event( "received hat" )
	$detect_player/player_collision.disabled = true
