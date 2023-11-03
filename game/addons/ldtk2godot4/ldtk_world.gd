class_name LDtkWorld extends Node2D

signal world_ready
signal level_ready( level : LDtkLevel )

@export var map : LDtkMap
@export var use_resource_loader : bool = true
@export_file( "*.tscn" ) var base_level_scene : String
@export_dir var base_level_folder : String


var _debug := true
var _resload : LDtkResourceLoader
var _cur_level : LDtkLevel
var _cur_entities : Array[Node2D]

func _ready() -> void:
	if use_resource_loader:
		_resload = LDtkResourceLoader.new( self, map, base_level_scene, base_level_folder )
		_resload.loading_complete.connect( _on_finished_loading )
		_resload.start_loading()



func _on_finished_loading() -> void:
	world_ready.emit()

func load_level( level_name : String ) -> void:
	call_deferred( "_load_level", level_name )

func _load_level( level_name : String ) -> void:
	# deactivate current entities
	for entity in _cur_entities:
		entity.hide()
		entity._entity_activate( false )
		_resload.release_entity( entity )
		entity.entity_iid = ""
		entity.position = LDtkResourceLoader._hidden_entity_position
	_cur_entities.clear()
	
	# deactivate current level
	if _cur_level:
		_cur_level.hide()
		_cur_level._activate( false )
		_cur_level.position = LDtkResourceLoader._hidden_level_position
		_cur_level.player_leaving_level.disconnect( _on_player_leaving_level )
		_cur_level = null
	
	# position and connect new level
	_cur_level = _resload.get_level( level_name )
	if not _cur_level:
		printerr( name, ": Unable to find level in resource loader - ", level_name )
	_cur_level.player_leaving_level.connect( _on_player_leaving_level )
	_cur_level.position *= 0
	
	# position and initialize new entities
	if _cur_level._map.entity_data[level_name].has( "entities" ):
		for entity_data in _cur_level._map.entity_data[level_name].entities:
			var entity = _resload.reserve_entity( entity_data.id )
			if not entity:
				printerr( name, ": Unable to find entity in resource loader - ", entity_data.id )
			entity.position = entity_data.position_px
			var aux_parameters = entity_data.parameters
			aux_parameters.size = entity_data.size
			entity._entity_initialize( aux_parameters )
			entity._entity_activate( true )
			entity.entity_iid = entity_data.iid
			_cur_entities.append( entity )
	
	# show level and entities
	_cur_level._activate( true )
	_cur_level.show()
	for entity in _cur_entities:
		entity.show()
	# all done
	level_ready.emit( _cur_level )


# This part of the code should not be here
# it needs to be overriden by the world class
func _on_player_leaving_level( player : Node2D, player_world_position : Vector2 ) -> void:
	return
	if _debug: print( "Player leaving level" )
	var new_level_name = map.get_level_name_at( player_world_position )
	if _debug: print( "New level: ", new_level_name )
	if not new_level_name:
		printerr( "Unable to find level" )
		return
	player._entity_activate( false )
	load_level( new_level_name )
	await level_ready
	player.position = player_world_position - Vector2( _cur_level.get_worldpos_px() )
	player._entity_activate( true )


