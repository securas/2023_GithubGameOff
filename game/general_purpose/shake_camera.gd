extends Camera2D

var parent : Node2D
var target_position : Vector2
var smooth_position : Vector2
var _shake_noise : FastNoiseLite
var _noise_coordinate = 0.0
var _is_shaking : float
var _shaking_magnitude : float


func _ready() -> void:
	top_level = true
	parent = get_parent()
	_reset_camera()
	_shake_noise = FastNoiseLite.new()
	_shake_noise.frequency = 20.0
	_shake_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	sigmgr.camera_shake.connect( shake )


func _reset_camera() -> void:
	target_position = parent.global_position
	smooth_position = target_position
	reset_smoothing()
	


func _process( delta : float ) -> void:
	target_position = parent.global_position
	target_position.x += parent._camera_offset
	smooth_position = lerp( smooth_position, target_position, 5 * delta )
	global_position = smooth_position.round()
	
	if _is_shaking > 0:
		_is_shaking -= delta	
		var _offset : Vector2
		_offset.x = _shake_noise.get_noise_1d( _noise_coordinate )
		_noise_coordinate += delta
		_offset.y = _shake_noise.get_noise_1d( _noise_coordinate )
		_offset *= 2.0
		_noise_coordinate += delta
		offset = _offset * _shaking_magnitude
		if _is_shaking <= 0:
			offset *= 0

func shake( duration : float, magnitude : float, frequency : float = 60.0 ) -> void:
	_is_shaking = duration
	_shaking_magnitude = magnitude
	_shake_noise.frequency = frequency
