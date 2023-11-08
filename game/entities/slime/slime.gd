extends CharacterBody2DPassiveEntity

const PATROL_VEL = 20.0
const CHASE_VEL = 30.0

enum SlimeStates { PATROL, CHASE, ATTACK }

var _slime_state : int = SlimeStates.PATROL
var _dir_nxt : int = 1
@onready var _rotate : Node2D = $rotate
@onready var _anim : CharacterAnim = $anim

func _entity_activate( a : bool ) -> void:
	if a:
		$DealDamageArea/damage_collision_floor.disabled = false
		$DealDamageArea/damage_collision_air.disabled = false
		_init_state_patrol()
		set_physics_process( true )
	else:
		$DealDamageArea/damage_collision_floor.disabled = true
		$DealDamageArea/damage_collision_air.disabled = true
		set_physics_process( false )
		_anim.stop()

func _entity_initialize( params : Dictionary ) -> void:
	_dir_nxt = params.dir_nxt


func _physics_process( delta : float ) -> void:
	match _slime_state:
		SlimeStates.PATROL:
			_state_patrol( delta )
	if _rotate.scale.x != _dir_nxt:
		_rotate.scale.x = float( _dir_nxt )
	

func _init_state_patrol() -> void:
	_slime_state = SlimeStates.PATROL
	_anim.anim_nxt = "patrol"
	$DealDamageArea/damage_collision_floor.disabled = false
	$DealDamageArea/damage_collision_air.disabled = true
	

func _state_patrol( delta : float ) -> void:
	pass
