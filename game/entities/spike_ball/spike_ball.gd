extends Node2DPassiveEntity

var _pivot : Vector2
var _pivot_dist : Vector2
var _delay : float
var _angvel : float
var _angle_to_pivot : float
var _start_timer : Timer
@onready var _ball_parts : Node2D = $ball_parts
@onready var _nparts : int = $ball_parts.get_child_count()

func _ready() -> void:
	_start_timer = Timer.new()
	_start_timer.one_shot = true
	_start_timer.autostart = false
	add_child( _start_timer )
	_start_timer.timeout.connect( _on_start_timer )
	$ball_parts.top_level = true

func _entity_activate( a : bool ) -> void:
	if a:
		$ball/ball_collision.disabled = false
		call_deferred( "_initialize_ball" )
	else:
		$ball/ball_collision.disabled = true
		$ball_parts.position = Vector2.ONE * 10000
		set_physics_process( false )

func _entity_initialize( params : Dictionary ) -> void:
	_delay = params.delay
	_angvel = params.angvel
	_pivot = Vector2( params.pivot.cx, params.pivot.cy ) * 8 + Vector2( 4, 4 )
	_pivot_dist = Vector2.RIGHT * ( position - _pivot ).length()
	var dist = position - _pivot
	_angle_to_pivot = dist.angle()
	_ball_parts.position = _pivot
	_set_ball_parts()

func _on_start_timer() -> void:
	set_physics_process( true )
	
func _initialize_ball() -> void:
	if _delay > 0:
		_start_timer.wait_time = _delay
		_start_timer.start()
	else:
		_on_start_timer()


func _physics_process( delta: float ) -> void:
	_angle_to_pivot = fmod( _angle_to_pivot + delta * _angvel, TAU )
	position = _pivot + _pivot_dist.rotated( _angle_to_pivot )
	_set_ball_parts()



func _set_ball_parts() -> void:
	var dist = position - _pivot
	for idx in range( _nparts ):
		_ball_parts.get_child( idx ).position = \
			( dist * float( idx ) / float( _nparts ) ).round()
		
