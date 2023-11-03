class_name Player extends CharacterBody2D

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
const CAMERA_OFFSET = 24.0
const CAMERA_OFFSET_VEL = 1.0

enum PlayerStates { FLOOR, AIR }

var _player_state_cur : int = -1
var _player_state_nxt : int = PlayerStates.AIR
var _player_state_lst : int = -1
var _dir_cur : int = 1
var _dir_nxt : int = 1
var _anim_cur : String
var _anim_nxt : String = "idle_nohat"
var _has_hat : bool = false
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


func _physics_process( delta : float ) -> void:
	_update_control()
	_fsm( delta )
	_update_direction()
	_update_camera_position( delta )
	_update_animation()

func _entity_activate( a : bool ) -> void:
	if a:
		set_physics_process( true )
		_control_enabled = true
	else:
		set_physics_process( false )
		_control_enabled = false


func _update_control() -> void:
	_control.dir = Input.get_action_strength( "btn_right" ) - Input.get_action_strength( "btn_left" )
	if _control_enabled:
		_control.is_moving = abs( _control.dir ) > 0.1
		_control.is_just_jump = Input.is_action_just_pressed( "btn_jump" )
		_control.is_jump = Input.is_action_pressed( "btn_jump" )
		_control.is_just_down = Input.is_action_just_pressed( "btn_down" )
		_control.is_down = Input.is_action_pressed( "btn_down" )
	else:
		_control.is_moving = false
		_control.is_just_jump = false
		_control.is_jump = false
		_control.is_just_down = false
		_control.is_down = false

func _update_direction() -> void:
	if _dir_cur != _dir_nxt:
		_dir_cur = _dir_nxt
		_rotate.scale.x = _dir_cur

func _update_camera_position( delta : float ) -> void:
	if not _camera: return
	if _control.is_moving:
		_camera_offset = lerp( _camera_offset, CAMERA_OFFSET * _dir_cur, delta * CAMERA_OFFSET_VEL )
	_camera.position.x = _camera_offset

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
		# Initialize new state
		match _player_state_cur:
			PlayerStates.FLOOR:
				_init_state_floor()
			PlayerStates.AIR:
				_init_state_air()
	# Run state
	match _player_state_cur:
		PlayerStates.FLOOR:
			_state_floor( delta )
		PlayerStates.AIR:
			_state_air( delta )




#--------------------------------------------------------------
# State Floor
#--------------------------------------------------------------
var _state_floor_params : Dictionary = {
	drop_platform_timer = 0.0,
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
}

func _init_state_air() -> void:
	_state_air_params.jump_buffer = 0.0
	_state_air_params.coyote_timer = COYOTE_MARGIN
	_state_air_params.variable_jump_timer = VARIABLE_JUMP_MARGIN
	if _state_air_params.is_jump:
		_anim_nxt = "jump" + _hat_anim()
	else:
		_anim_nxt = "fall" + _hat_anim()

func _terminate_state_air() -> void:
	_state_air_params.is_jump = false

func _state_air( delta : float ) -> void:
	# coyote timer
	if not _state_air_params.is_jump and _state_air_params.coyote_timer > 0:
		_state_air_params.coyote_timer -= delta
		if _control.is_just_jump:
			_jump()
			_init_state_air()
			return
	# variable jump height
	if _state_air_params.is_jump:
		if _state_air_params.variable_jump_timer >= 0:
			_state_air_params.variable_jump_timer -= delta
			if not _control.is_jump or _state_air_params.variable_jump_timer < 0:
				velocity.y *= 0.5
				_state_air_params.variable_jump_timer = -1.0
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
	
