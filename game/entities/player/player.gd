class_name Player extends CharacterBody2D

signal player_dead

const GRAVITY = 900
const TERM_VEL = 200#350
const JUMP_VEL = 280#380
const JUMP_BUFFER_MARGIN = 0.15
const VARIABLE_JUMP_MARGIN = 0.2
const COYOTE_MARGIN = 0.15
const FLOOR_VEL = 70#80
const DROP_PLATFORM_MARGIN = 0.1
const AIR_VEL = 70#80
const AIR_ACCEL = 10
const AIR_DECEL = 5
const HIT_TIMEOUT = 0.05
const HIT_THROWBACK_VEL = 100
const INVULNERABLE_TIMEOUT = 0.3
const CAMERA_OFFSET = 24.0
const CAMERA_OFFSET_VEL = 1.0

enum PlayerStates { FLOOR, AIR, HIT, DEAD }

var _player_state_cur : int = -1
var _player_state_nxt : int = PlayerStates.AIR
var _player_state_lst : int = -1
var _dir_cur : int = 1
var _dir_nxt : int = 1
var _anim_cur : String
var _anim_nxt : String = "idle"
var _has_hat : bool = false#true
var _hat_jump : bool = false
var _is_hit : bool = false
var _is_invulnerable : bool = false
#var _is_dead : bool = false
var _invulnerable_timer : float = 0.0
var _camera_offset : float = 0.0
var _control_enabled : bool = true
var _control : Dictionary = {
	is_moving = false,
	dir = 0.0,
	is_jump = false,
	is_just_jump = false,
	is_down = false,
	is_just_down = false,
}

@onready var _rotate : Node2D = $rotate
@onready var _camera : Camera2D = $camera
@onready var _anim : AnimationPlayer = $anim
@onready var _hat : PlayerHat = $hat
@onready var _detect_hazards : Area2D = $detect_hazards

#--------------------------------------------------------------
# hat functions
#--------------------------------------------------------------
func catch() -> void:
	if _player_state_cur == PlayerStates.AIR:
		_state_air_params.catch_timer = 0.2
	else:
		_state_floor_params.catch_timer = 0.2
	_anim_nxt = "catch"

func hat_jump() -> void:
	_jump()
	_hat_jump = true
	#velocity.y *= 2.0
	_init_state_air()
	
#--------------------------------------------------------------
# standard functions
#--------------------------------------------------------------
func _ready() -> void:
	game.player = self
	_has_hat = game.state.has_hat

func _physics_process( delta : float ) -> void:
	_update_control()
	_fsm( delta )
	_update_direction()
	_update_camera_position( delta )
	_update_animation()
	_check_hazards()
	
	if _is_invulnerable:
		_invulnerable_timer -= delta
		if _invulnerable_timer <= 0:
			_is_invulnerable = false
			$rotate/player.stop()


func _entity_activate( a : bool ) -> void:
	if a:
		_anim.play()
		set_physics_process( true )
		_control_enabled = true
	else:
		set_physics_process( false )
		_control_enabled = false
		_anim.stop( true )

func _update_control() -> void:
	_control.dir = Input.get_action_strength( "btn_right" ) - Input.get_action_strength( "btn_left" )
	if _control_enabled:
		_control.is_moving = abs( _control.dir ) > 0.1
		_control.is_just_jump = Input.is_action_just_pressed( "btn_jump" )
		_control.is_jump = Input.is_action_pressed( "btn_jump" )
		_control.is_just_down = Input.is_action_just_pressed( "btn_down" )
		_control.is_down = Input.is_action_pressed( "btn_down" )
		_control.is_attack = Input.is_action_pressed( "btn_attack" )
		_control.is_just_attack = Input.is_action_just_pressed( "btn_attack" )
	else:
		_control.is_moving = false
		_control.is_just_jump = false
		_control.is_jump = false
		_control.is_just_down = false
		_control.is_down = false
		_control.is_attack = false
		_control.is_just_attack = false

func _update_direction() -> void:
	if _dir_cur != _dir_nxt:
		_dir_cur = _dir_nxt
		_rotate.scale.x = _dir_cur

func _update_camera_position( delta : float ) -> void:
	if not _camera: return
	if _control.is_moving:
		_camera_offset = lerp( _camera_offset, CAMERA_OFFSET * _dir_cur, delta * CAMERA_OFFSET_VEL )
	#_camera.position.x = _camera_offset

func _update_animation() -> void:
	if _anim_cur != _anim_nxt:
		_anim_cur = _anim_nxt
		_anim.play( _anim_cur )

func _hat_anim() -> String:
	if _has_hat: return "_hat"
	return "_nohat"
	
#--------------------------------------------------------------
# States Machine
#--------------------------------------------------------------
func _fsm( delta : float ) -> void:
	# Update state
	if _player_state_cur != _player_state_nxt:
		# Changing state
		_player_state_lst = _player_state_cur
		_player_state_cur = _player_state_nxt
		# Terminate previous state
		match _player_state_lst:
			PlayerStates.FLOOR:
				_terminate_state_floor()
			PlayerStates.AIR:
				_terminate_state_air()
			PlayerStates.HIT:
				_terminate_state_hit()
			PlayerStates.DEAD:
				_terminate_state_dead()
		# Initialize new state
		match _player_state_cur:
			PlayerStates.FLOOR:
				_init_state_floor()
			PlayerStates.AIR:
				_init_state_air()
			PlayerStates.HIT:
				_init_state_hit()
			PlayerStates.DEAD:
				_init_state_dead()
	# Run state
	match _player_state_cur:
		PlayerStates.FLOOR:
			_state_floor( delta )
		PlayerStates.AIR:
			_state_air( delta )
		PlayerStates.HIT:
			_state_hit( delta )
		PlayerStates.DEAD:
			_state_dead( delta )




#--------------------------------------------------------------
# State Floor
#--------------------------------------------------------------
var _state_floor_params : Dictionary = {
	drop_platform_timer = 0.0,
	throw_timer = 0.0,
	catch_timer = 0.0,
}

func _init_state_floor() -> void:
	_state_floor_params.drop_platform_timer = DROP_PLATFORM_MARGIN
	if abs( velocity.x ) > 1.0:
		_anim_nxt = "run" + _hat_anim()
	else:
		_anim_nxt = "idle" + _hat_anim()

func _terminate_state_floor() -> void:
	pass

func _state_floor( delta : float ) -> void:
	if _control.is_just_attack:
		if _has_hat:
			_hat.hat_throw()
			_has_hat = false
			_state_floor_params.throw_timer = 0.25
			_anim_nxt = "throw"
		else:
			if game.state.has_hat:
				_hat.hat_return()
	if _state_floor_params.throw_timer > 0.0:
		_state_floor_params.throw_timer -= delta
		return
	
	if _state_floor_params.catch_timer > 0.0:
		_state_floor_params.catch_timer -= delta
		return
	
	if _control.is_just_jump:
		_jump()
		_player_state_nxt = PlayerStates.AIR
		return
	
	if _control.is_moving:
		_dir_nxt = sign( _control.dir )
		velocity.x = FLOOR_VEL * _dir_nxt
		_anim_nxt = "run" + _hat_anim()
	else:
		velocity.x = 0
		position = position.round()
		_anim_nxt = "idle" + _hat_anim()
	
	
	
	
	_gravity( delta )
	var _collided = move_and_slide()
	if not is_on_floor():
		_player_state_nxt = PlayerStates.AIR
	else:
		position.y = round( position.y )
		if _control.is_down and _check_one_way_platform():
			_state_floor_params.drop_platform_timer -= delta
			if _state_floor_params.drop_platform_timer <= 0:
				position.y += 1
				_player_state_nxt = PlayerStates.AIR
				return
		else:
			_state_floor_params.drop_platform_timer = DROP_PLATFORM_MARGIN

#--------------------------------------------------------------
# State Air
#--------------------------------------------------------------
var _state_air_params : Dictionary = {
	is_jump = false,
	jump_buffer = 0.0,
	coyote_timer = 0.0,
	variable_jump_timer = 0.0,
	throw_timer = 0.0,
	catch_timer = 0.0,
}

func _init_state_air() -> void:
	_state_air_params.jump_buffer = 0.0
	_state_air_params.coyote_timer = COYOTE_MARGIN
	_state_air_params.variable_jump_timer = VARIABLE_JUMP_MARGIN
	_state_air_params.throw_timer = 0.0
	_state_air_params.catch_timer = 0.0
	if _state_air_params.is_jump:
		_anim_nxt = "jump" + _hat_anim()
	else:
		_anim_nxt = "fall" + _hat_anim()

func _terminate_state_air() -> void:
	_state_air_params.is_jump = false
	_hat_jump = false

func _state_air( delta : float ) -> void:
	# coyote timer
	if not _state_air_params.is_jump and _state_air_params.coyote_timer > 0:
		_state_air_params.coyote_timer -= delta
		if _control.is_just_jump:
			_jump()
			_init_state_air()
			return
	# variable jump height
	if _state_air_params.is_jump and not _hat_jump:
		if _state_air_params.variable_jump_timer >= 0:
			_state_air_params.variable_jump_timer -= delta
			if not _control.is_jump or _state_air_params.variable_jump_timer < 0:
				velocity.y *= 0.5
				_state_air_params.variable_jump_timer = -1.0
	
	if _control.is_just_attack:
		if _has_hat:
			_hat.hat_throw()
			_has_hat = false
			_state_air_params.throw_timer = 0.25
			_anim_nxt = "throw"
		else:
			if game.state.has_hat:
				_hat.hat_return()
	if _state_air_params.throw_timer > 0.0:
		_state_air_params.throw_timer -= delta
		if _control.is_just_jump:
			_jump()
			_init_state_air()
			return
		if _state_air_params.throw_timer <= 0:
			if _state_air_params.is_jump:
				_anim_nxt = "jump" + _hat_anim()
			else:
				_anim_nxt = "fall" + _hat_anim()
		return
	
	if _state_air_params.catch_timer > 0.0:
		_state_air_params.catch_timer -= delta
		if _state_air_params.catch_timer <= 0:
			if velocity.y < 0:
				_anim_nxt = "jump" + _hat_anim()
			else:
				_anim_nxt = "fall" + _hat_anim()
		return
	
	# control and motion
	if _control.is_moving:
		_dir_nxt = sign( _control.dir )
		velocity.x = lerp( velocity.x, AIR_VEL * float( _dir_nxt ), AIR_ACCEL * delta )
	else:
		velocity.x = lerp( velocity.x, 0.0, AIR_DECEL * delta )
	_gravity( delta )
	var _collided = move_and_slide()
	if velocity.y > 0:
		_anim_nxt = "fall" + _hat_anim()
	
	# jump buffer
	_state_air_params.jump_buffer -= delta
	if _control.is_just_jump: _state_air_params.jump_buffer = JUMP_BUFFER_MARGIN
	# reach the floor
	if is_on_floor():
		if _state_air_params.jump_buffer > 0:
			_jump()
			_init_state_air()
			return
		position = position.round()
		_player_state_nxt = PlayerStates.FLOOR
		$anim_fx.play( "land" )
		$anim_fx.queue( "RESET" )


#--------------------------------------------------------------
# State Hit
#--------------------------------------------------------------
var _state_hit_params : Dictionary = {
	hit_timer = HIT_TIMEOUT,
	hit_dir = Vector2.ZERO
}
func _init_state_hit() -> void:
	_state_hit_params.hit_timer = HIT_TIMEOUT
	$rotate/player.flash(0.3)
	velocity = _state_hit_params.hit_dir

func _terminate_state_hit() -> void:
	_is_hit = false

func _state_hit( delta : float ) -> void:
	var _hit = move_and_slide()
	_state_hit_params.hit_timer -= delta
	if _state_hit_params.hit_timer <= 0:
		_player_state_nxt = PlayerStates.AIR




#--------------------------------------------------------------
# State Dead
#--------------------------------------------------------------
var _state_dead_params : Dictionary = {
	dead_timer = 2.0,
}
func _init_state_dead() -> void:
	_state_dead_params.dead_timer = 2.0

func _terminate_state_dead() -> void:
	_is_hit = false

func _state_dead( delta : float ) -> void:
	if _state_dead_params.dead_timer > 0:
		_state_dead_params.dead_timer -= delta
		if _state_dead_params.dead_timer <= 0:
			player_dead.emit()
			_player_state_nxt = PlayerStates.AIR






#--------------------------------------------------------------
# Damage
#--------------------------------------------------------------
func _on_receiving_damage( from : Node, damage : int ) -> void:
	if _is_hit or _is_invulnerable: return
	_is_hit = true
	
	var nxt_energy = game.state.energy - damage # this is to avoid triggering hud
	nxt_energy = nxt_energy if nxt_energy >= 0 else 0
	game.state.energy = nxt_energy # now its ok to trigger the hub
	if game.state.energy == 0:
		# dead
		_player_state_nxt = PlayerStates.DEAD
		_is_invulnerable = false
		sigmgr.camera_shake.emit( 0.3, 2, 60 )
	else:
		# still alive
		sigmgr.camera_shake.emit( 0.2, 2, 60 )
		_player_state_nxt = PlayerStates.HIT
		_is_invulnerable = true
		_invulnerable_timer = INVULNERABLE_TIMEOUT
		if velocity.length() > 5:
			_state_hit_params.hit_dir = -velocity.normalized() * HIT_THROWBACK_VEL
		else:
			_state_hit_params.hit_dir = ( global_position - from.global_position ).normalized() * HIT_THROWBACK_VEL

func _check_hazards() -> void:
	if _is_hit or _is_invulnerable: return
	var hazards = _detect_hazards.get_overlapping_bodies()
	hazards.append_array( _detect_hazards.get_overlapping_areas() )
	if not hazards: return
	_is_hit = true
	var nxt_energy = game.state.energy - 1 # this is to avoid triggering hud
	nxt_energy = nxt_energy if nxt_energy >= 0 else 0
	game.state.energy = nxt_energy
	if game.state.energy == 0:
		# dead
		_player_state_nxt = PlayerStates.DEAD
		_is_invulnerable = false
		sigmgr.camera_shake.emit( 0.3, 2, 60 )
	else:
		# still alive
		_player_state_nxt = PlayerStates.HIT
		_is_invulnerable = true
		_invulnerable_timer = INVULNERABLE_TIMEOUT
		_state_hit_params.hit_dir = Vector2( 0, -HIT_THROWBACK_VEL * 2 )
		sigmgr.camera_shake.emit( 0.2, 2, 60 )


#--------------------------------------------------------------
# Useful methods - Could be moved to an Actor class
#--------------------------------------------------------------
func _gravity( delta : float, multiplier : float = 1.0 ) -> void:
	velocity.y = min( velocity.y + multiplier * GRAVITY * delta, TERM_VEL )

func _jump() -> void:
	$anim_fx.play( "jump" )
	$anim_fx.queue( "RESET" )
	velocity.y = -JUMP_VEL
	_state_air_params.is_jump = true
	#var _collided = move_and_slide()

func _check_one_way_platform() -> bool:
	var t : Transform2D = global_transform
	return not test_move( t.translated( Vector2( 0, 1 ) ), Vector2( 0, 1 ) )
	
