extends Camera2D

var parent : Node2D
var target_position : Vector2
var smooth_position : Vector2

func _ready() -> void:
	top_level = true
	parent = get_parent()
	_reset_camera()


func _reset_camera() -> void:
	target_position = parent.global_position
	smooth_position = target_position
	reset_smoothing()


func _process( delta : float ) -> void:
	target_position = parent.global_position
	target_position.x += parent._camera_offset
	smooth_position = lerp( smooth_position, target_position, 5 * delta )
	global_position = smooth_position.round()
