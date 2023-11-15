extends CharacterBody2DPassiveEntity

const PATROL_VEL = 16.0
const POSITION_OFFSET = Vector2( 0, -2 )
const MAX_ENERGY = 1

enum EnemyStates { PATROL, DEAD }

var _enemy_state : int = EnemyStates.PATROL
var _dir_nxt : int = 1
var _dir_cur : int = -1
var _energy : int
var _path : Array[Vector2]


@onready var _rotate_crab : Node2D = $rotate/crab
@onready var _anim : CharacterAnim = $anim


func _entity_activate( a : bool ) -> void:
	if a:
		$DealDamageArea/damage_collision.disabled = false
		$RcvDamageArea/rcv_damage_collision.disabled = false
		_init_state_patrol()
		$rotate/crab.show()
		set_physics_process( true )
		_energy = MAX_ENERGY
	else:
		$DealDamageArea/damage_collision.disabled = true
		$RcvDamageArea/rcv_damage_collision.disabled = true
		set_physics_process( false )
		if _anim: _anim.stop()

func _entity_initialize( params : Dictionary ) -> void:
	_dir_nxt = params.dir_nxt
	var _down = Vector2.DOWN
	$rotate.rotation = _down.angle_to( Vector2.DOWN )
	_path = []
	_path.append( position )
	_path.append( Vector2( params.path.cx, params.path.cy ) * 8 + Vector2( 4, 8 ) )
	$rotate.rotation = params.direction * PI / 2.0


func _physics_process( delta : float ) -> void:
	#print( "crab: ", name )
	match _enemy_state:
		EnemyStates.PATROL:
			_state_patrol( delta )
	if _dir_cur != _dir_nxt:
		_dir_cur = _dir_nxt
		_rotate_crab.scale.x = float( _dir_cur )
	_anim.update_anim()

#--------------------------------------------
# state patrol
#--------------------------------------------
var _state_patrol_params := {
	t = 0.0,
	dir = 1,
	vel = 1.0
}
func _init_state_patrol() -> void:
	_enemy_state = EnemyStates.PATROL
	_anim.anim_cur = ""
	_anim.anim_nxt = "patrol"
	$DealDamageArea/damage_collision.disabled = false
	$RcvDamageArea/rcv_damage_collision.disabled = false
	_state_patrol_params.vel = PATROL_VEL / ( _path[0] - _path[1] ).length()


func _state_patrol( delta : float ) -> void:
	if _state_patrol_params.dir == 1:
		position = lerp( _path[0], _path[1], _state_patrol_params.t )
	else:
		position = lerp( _path[1], _path[0], _state_patrol_params.t )
	_state_patrol_params.t += _state_patrol_params.vel * delta
	if _state_patrol_params.t > 1:
		_state_patrol_params.dir *= -1
		_dir_nxt *= -1
		_state_patrol_params.t = 0.0







func _init_state_dead() -> void:
	sigmgr.camera_shake.emit( 0.2, 1, 60 )
	_enemy_state = EnemyStates.DEAD
	$DealDamageArea/damage_collision.call_deferred( "set_disabled", true )
	$RcvDamageArea/rcv_damage_collision.call_deferred( "set_disabled", true )
	$rotate/crab.hide()
	$medium_explosion.explode()

#--------------------------------------------
# damage
#--------------------------------------------
func _on_receiving_damage( _from : Node, damage : int ) -> void:
	_energy -= damage
	if _energy > 0:
		sigmgr.camera_shake.emit( 0.1, 1, 60 )
		$rotate/crab.flash( 0.1 )
	else:
		_init_state_dead()
	pass

