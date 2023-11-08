extends LDtkWorld

@onready var camera : Camera2D = $player/camera
@onready var player : Player = $player

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	$fade_layer.fade_out( true )
	super._ready()
	world_ready.connect( _on_world_ready )
	#level_ready.connect( _on_level_ready )

func _on_world_ready() -> void:
	var starting_level = map.get_level_name_at( game.state.worldpos_px )#
	starting_level = map.get_level_name_at( $player.global_position )
	if starting_level:
		player._entity_activate( false )
		_load_level( starting_level )
		camera.limit_left = 0
		camera.limit_right = _cur_level.get_worldsize_px().x
		camera.limit_top = 0
		camera.limit_bottom = round( _cur_level.get_worldsize_px().y / 180.0 ) * 180.0
		camera.reset_smoothing()
		#player.global_position = game.state.worldpos_px
		player.global_position -= Vector2( _cur_level.get_worldpos_px() )
		$fade_layer.fade_in()
		camera.reset_smoothing()
		$fade_layer.fade_in()
		await $fade_layer.fade_complete
		player._entity_activate( true )
	else:
		load_level( "level_0" )
		await level_ready
		$fade_layer.fade_in()



func _on_player_leaving_level( player : Node2D, player_world_position : Vector2 ) -> void:
	var new_level_name = map.get_level_name_at( player_world_position )
	if _debug: print( "New level: ", new_level_name, " at ", player_world_position )
	if not new_level_name:
		printerr( "Unable to find level" )
		return
	player._entity_activate( false )
	$fade_layer.fade_out()
	await $fade_layer.fade_complete
	load_level( new_level_name )
	await level_ready
	var hat_offset = player.global_position - player._hat.global_position
	player.position = player_world_position - Vector2( _cur_level.get_worldpos_px() )
	player._hat.global_position = player.global_position - hat_offset
	camera.limit_left = 0
	camera.limit_right = _cur_level.get_worldsize_px().x
	camera.limit_top = 0
	camera.limit_bottom = round( _cur_level.get_worldsize_px().y / 180.0 ) * 180.0
	#camera.reset_smoothing()
	camera._reset_camera() # NEW
	$fade_layer.fade_in()
	await $fade_layer.fade_complete
	player._entity_activate( true )
