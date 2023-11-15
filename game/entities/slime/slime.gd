extends CharacterBody2DPassiveEntity

const PATROL_VEL = 15.0
const PATROL_VIEW_RANGE = 64.0
const CHASE_VEL = 20.0
const CHASE_VIEW_RANGE = 96.0
const CHASE_QUIT_TIME = 1.0
const CHASE_TURN_WAIT = 0.25
const WAIT_TIME = 1.0
const ATTACK_WAIT = 0.5
const GRAVITY = 300
const TERM_VEL = 200
const POSITION_OFFSET = Vector2( 0, -2 )
const MAX_ENERGY = 1

enum SlimeStates { PATROL, CHASE, WAIT, ATTACK, DEAD }

var _slime_state : int = SlimeStates.PATROL
var _dir_nxt : int = 1
var _dir_cur : int = -1
var _energy : int

@onready var _rotate : Node2D = $rotate
@onready var _anim : CharacterAnim = $anim

func _entity_activate( a : bool ) -> void:
	if a:
		$collision.disabled = false
		$rotate/attack_area/attack_collision.disabled = false
		$DealDamageArea/damage_collision.disabled = false
		$RcvDamageArea/rcv_damage_collision.disabled = false
		_init_state_patrol()
		$rotate/slime.show()
		set_physics_process( true )
		_energy = MAX_ENERGY
	else:
		$collision.disabled = true
		$rotate/attack_area/attack_collision.disabled = true
		$DealDamageArea/damage_collision.disabled = true
		$RcvDamageArea/rcv_damage_collision.disabled = true
		set_physics_process( false )
		if _anim: _anim.stop()

func _entity_initialize( params : Dictionary ) -> void:
	_dir_nxt = params.dir_nxt


func _physics_process( delta : float ) -> void:
	match _slime_state:
		SlimeStates.PATROL:
			_state_patrol( delta )
		SlimeStates.CHASE:
			_state_chase( delta )
		SlimeStates.WAIT:
			_state_wait( delta )
		SlimeStates.ATTACK:
			_state_attack( delta )
	
	if _dir_cur != _dir_nxt:
		_dir_cur = _dir_nxt
		_rotate.scale.x = float( _dir_cur )
	_anim.update_anim()

#--------------------------------------------
# state patrol
#--------------------------------------------
func _init_state_patrol() -> void:
	_slime_state = SlimeStates.PATROL
	_anim.anim_cur = ""
	_anim.anim_nxt = "patrol"
	$DealDamageArea/damage_collision.disabled = false

func _state_patrol( delta : float ) -> void:
	if _is_at_border( delta ):
		_dir_nxt *= -1
	velocity.x = PATROL_VEL * _rotate.scale.x
	_gravity( delta )
	move_and_slide()
	
	if _check_player( PATROL_VIEW_RANGE ):
		
		_init_state_chase()

#--------------------------------------------
# state chase
#--------------------------------------------
var _state_chase_params = {
	chase_wait = 0.0,
	turn_timer = 0.0
}
func _init_state_chase() -> void:
	_slime_state = SlimeStates.CHASE
	_anim.anim_cur = ""
	_anim.anim_nxt = "chase"
	$DealDamageArea/damage_collision.disabled = false
	_state_chase_params.chase_wait = 0.0
	_state_chase_params.turn_timer = 0.0

func _state_chase( delta : float ) -> void:
	if _is_at_border( delta ):
		_init_state_wait()
	
	velocity.x = CHASE_VEL * _rotate.scale.x
	_gravity( delta )
	move_and_slide()
	
	if not _check_player( CHASE_VIEW_RANGE ):
		_state_chase_params.chase_wait += delta
		if _state_chase_params.chase_wait > CHASE_QUIT_TIME:
			_init_state_wait()
	else:
		_state_chase_params.chase_wait = 0.0
	
	if game.player:
		var dist = game.player.global_position.x - global_position.x
		if sign( dist ) != _dir_cur:
			_state_chase_params.turn_timer += delta
			if _state_chase_params.turn_timer > CHASE_TURN_WAIT:
				_dir_nxt = int( sign( dist ) )
		else:
			_state_chase_params.turn_timer = 0.0
		
		var colliders = $rotate/attack_area.get_overlapping_bodies()
		if colliders:
			_init_state_attack()

#--------------------------------------------
# state wait
#--------------------------------------------
var _state_wait_params = {
	wait_timer = 0.0,
}
func _init_state_wait() -> void:
	_slime_state = SlimeStates.WAIT
	_anim.anim_cur = ""
	_anim.anim_nxt = "wait"
	$DealDamageArea/damage_collision.disabled = false
	_state_wait_params.wait_timer = 0.0

func _state_wait( delta : float ) -> void:
	_state_wait_params.wait_timer += delta
	if _state_wait_params.wait_timer >= WAIT_TIME:
		_init_state_patrol()
		return
	
	if _check_player( CHASE_VIEW_RANGE ):
		_init_state_chase()

#--------------------------------------------
# state attack
#--------------------------------------------
var _state_attack_params = {
	wait_timer = 0.0,
}
func _init_state_attack() -> void:
	_slime_state = SlimeStates.ATTACK
	_state_attack_params.wait_timer = ATTACK_WAIT
	velocity *= 0.0
	_anim.anim_nxt = "prepare_attack"

func _state_attack( delta : float ) -> void:
	if _state_attack_params.wait_timer > 0:
		_state_attack_params.wait_timer -= delta
		if _state_attack_params.wait_timer <= 0:
			var dist = min( abs( game.player.global_position.x - global_position.x ), 32 )
			velocity.y = -90 * dist / 32
			velocity.x = 70 * _dir_cur
			_anim.anim_nxt = "attack_up"
		_gravity( delta )
		move_and_slide()
	else:
		_gravity( delta )
		if velocity.y > 0:
			_anim.anim_nxt = "attack_down"
		if move_and_slide():
			var dist = game.player.global_position.x - global_position.x
			_dir_nxt = int( sign( dist ) )
			_init_state_patrol()


func _init_state_dead() -> void:
	sigmgr.camera_shake.emit( 0.2, 1, 60 )
	_slime_state = SlimeStates.DEAD
	$collision.call_deferred( "set_disabled", true )
	$rotate/attack_area/attack_collision.call_deferred( "set_disabled", true )
	$DealDamageArea/damage_collision.call_deferred( "set_disabled", true )
	$RcvDamageArea/rcv_damage_collision.call_deferred( "set_disabled", true )
	$rotate/slime.hide()
	$medium_explosion.explode()

#--------------------------------------------
# damage
#--------------------------------------------
func _on_receiving_damage( _from : Node, damage : int ) -> void:
	_energy -= damage
	if _energy > 0:
		$rotate/slime.flash( 0.1 )
		sigmgr.camera_shake.emit( 0.1, 1, 60 )
	else:
		_init_state_dead()
	pass

#--------------------------------------------
# Useful methods
#--------------------------------------------
func _gravity( delta : float, multiplier : float = 1.0 ) -> void:
	velocity.y = min( velocity.y + multiplier * GRAVITY * delta, TERM_VEL )

func _is_at_border( delta : float, check_back : bool = false ) -> bool:
	var gtrans = global_transform
	var tfall = test_move( \
		gtrans.translated( Vector2.RIGHT * 8 * _dir_cur ), \
			Vector2.DOWN * 8 )
	if not tfall: return true
	if check_back:
		tfall = test_move( \
			gtrans.translated( Vector2.LEFT * 8 * _dir_cur ), \
			Vector2.DOWN )
		if not tfall: return true
	# test wall
	var wall_vel = Vector2.RIGHT * _dir_cur * 100 # cheating
	var wall = test_move( gtrans, wall_vel * delta )
	if wall: return true
	return false

func _check_player( reach : float ) -> bool:
	if not game.player: return false
	return _target_in_sight(
		global_position + POSITION_OFFSET,
		game.player.global_position + Vector2( 0, -6 ),
		reach,
		_dir_cur,
		0.7,
		[],
		1
	)


func _target_in_sight( sourcepos : Vector2, targetpos : Vector2, \
		max_dist : float, view_direction : float, view_angle : float, exclude : Array, colmask : int ) -> bool:
	var dist = targetpos - sourcepos
	# check maximum distance
	if max_dist > 0 and dist.length() > max_dist:
		return false
	# check if direction dependent view in the horizontal axis
	if abs( dist.x ) > 0.0 and abs( view_direction) > 0.0:
		if sign( dist.x ) != sign( view_direction ):
			return false
		# if there is a view direction, then also checks the view angle
		if abs( dist.angle_to( Vector2.RIGHT * sign( dist.x ) ) ) > view_angle:
			return false
	# check the view angle
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create( sourcepos, targetpos, colmask, exclude )
	var result = space_state.intersect_ray( query )
	if not result: return true
#	print( "obstacle: ", result.collider.name )
	return false
