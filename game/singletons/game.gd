extends Node

var debug := true
var state : Dictionary
#var player : Node2D

func _ready() -> void:
	_set_initial_gamestate()


func _set_initial_gamestate() -> void:
	state = {
		events = [],
		worldpos_px = Vector2i( 160, 128 ),
		hat_travel_time = 0.110,
		hat_velocity = 200.0,
		has_hat = false,
	}
	if debug:
		_set_debug_gamestate()
	

func _set_debug_gamestate() -> void:
	add_event( "received hat" )
	state.has_hat = true


#-----------------------
# Manage events
#-----------------------
func is_event( evt_name : String ) -> bool:
	if state.events.find( evt_name ) > -1:
		return true
	return false

func add_event( evt_name : String ) -> bool:
	if is_event( evt_name ): return false
	state.events.append( evt_name )
	return true
