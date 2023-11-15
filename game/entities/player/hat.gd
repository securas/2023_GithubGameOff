class_name PlayerHat extends CharacterBody2D

enum HatStates { HIDDEN, THROW, SLOW, RETURN, HIT }

var _hat_state : int = HatStates.HIDDEN
var _player : Node2D
var _jump_enable_timer : float
var _anim_nxt := "cycle"
var _anim_cur := ""
@onready var _anim : AnimationPlayer = $anim
@onready var _hat = $hat

func hat_throw() -> void:
	_init_state_throw()
func hat_return() -> void:
	_init_state_return()


func _ready() -> void:
	_player = get_parent()
	top_level = true
	_init_state_hidden()

func _entity_activate( a : bool ) -> void:
	if a:
		_anim.play()
		set_physics_process( true )
	else:
		set_physics_process( false )
		_anim.stop( true )


func _physics_process( delta : float ) -> void:
	match _hat_state:
		HatStates.HIDDEN:
			# do nothing
			pass
		HatStates.THROW:
			_state_throw( delta )
		HatStates.RETURN:
			_state_return( delta )
		HatStates.HIT:
			_state_hit( delta )
	if _anim_cur != _anim_nxt:
		_anim_cur = _anim_nxt
		_anim.play( _anim_cur )


func _init_state_hidden() -> void:
	_hat_state = HatStates.HIDDEN
	hide()
	$hat_collision.disabled = true
	$detect_player/player_collision.disabled = true
	$player_jump/jump_collision.disabled = true
	$DealDamageArea/damage_collision.disabled = true
	_jump_enable_timer = 0.2

var _throw_properties = {
	travel_time = 0.0
}
func _init_state_throw() -> void:
	_anim_nxt = "cycle"
	_hat_state = HatStates.THROW
	global_position = _player.global_position + Vector2( 0, -6 )
	velocity = Vector2( game.state.hat_velocity * _player._dir_cur, 0.0 )
	show()
	$hat_collision.disabled = false
	$detect_player/player_collision.disabled = true
	$DealDamageArea/damage_collision.disabled = false
	_throw_properties.travel_time = game.state.hat_travel_time
	_hat.scale.x = sign( velocity.x )

func _state_throw( delta : float ) -> void:
	var coldata = move_and_collide( velocity * delta )
	if coldata:
		_init_state_hit()
		return
	_throw_properties.travel_time -= delta
	if _throw_properties.travel_time <= 0:
		velocity.x = lerp( velocity.x, 0.0, 10.0 * delta )
		if abs( velocity.x ) < 1:
			velocity.x = 0.0
			if _throw_properties.travel_time < -2.0:
				_init_state_return()
	if _jump_enable_timer > 0:
		_jump_enable_timer -= delta
		if _jump_enable_timer <= 0:
			$player_jump/jump_collision.disabled = false




var _hit_timer : float

func _init_state_hit() -> void:
	_anim_nxt = "hit"
	_hat_state = HatStates.HIT
	_hit_timer = 5.0
	velocity *= 0
	$player_jump/jump_collision.disabled = false
	$DealDamageArea/damage_collision.disabled = true
func _state_hit( delta : float ) -> void:
	_hit_timer -= delta
	if _hit_timer <= 0:
		_init_state_return()


func _init_state_return() -> void:
	_anim_nxt = "cycle"
	_hat_state = HatStates.RETURN
	$hat_collision.disabled = true
	$detect_player/player_collision.disabled = false
	$DealDamageArea/damage_collision.disabled = false

func _state_return( delta : float ) -> void:
	var dist = _player.global_position - global_position + Vector2( 0, -6 )
	var desired_velocity = dist.normalized() * game.state.hat_velocity * 0.8
	
	var max_force = 7.0
	if dist.normalized().dot(velocity.normalized()) < 0:
		max_force = 14
	var force = ( desired_velocity - velocity ).limit_length( max_force )
	velocity += force
	velocity = velocity.limit_length( game.state.hat_velocity )
	_hat.scale.x = sign( velocity.x )
	var _coldata = move_and_collide( velocity * delta )

func _on_detect_player_body_entered( _node : Node2D ) -> void:
	_player._has_hat = true
	_player.catch()
	_init_state_hidden()


func _on_player_jump_body_entered( player : Player ) -> void:
	if _hat_state == HatStates.RETURN:
		return
	#print( player.global_position.y, " ", $player_jump.global_position.y )
	if player.global_position.y > $player_jump.global_position.y:
		return
	if player._player_state_cur != Player.PlayerStates.AIR:
		return
	if player.velocity.y <= 0:
		return
	player.hat_jump()
	$anim_fx.stop()
	$anim_fx.play( "jump" )
	$anim_fx.queue( "RESET" )
