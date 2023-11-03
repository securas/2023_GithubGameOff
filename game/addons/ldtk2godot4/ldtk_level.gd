@tool
class_name LDtkLevel extends Node2D


signal player_leaving_level( player, player_world_position )


@export var _map : LDtkMap = null : set = _set_map
@export var _detect_player := true
@export_flags_2d_physics var _player_detection_mask : int
@export var _player_detection_grace_time : float

var level_name : String
var rect : Rect2i
var entities : Array[Dictionary]

var _debug := false
var _level_limits_created := false

var _detect_width := -4
var _detect_margin := 4.0
var _report_offset := 8.0
var _update_ingame := false
#var _detection_areas := {}
var _detection_area : Area2D

#----------------------------
# Methods to Override
#----------------------------
func _activate( _act : bool = true) -> void:
	pass

#----------------------------
# Setters
#----------------------------
func _set_map( v : LDtkMap ) -> void:
	_map = v
	if Engine.is_editor_hint() and name:
		_update_map()
	
#----------------------------
# Enter Tree
#----------------------------
func _enter_tree() -> void:
	if _debug: print( name, ": Entering tree" )
	if not Engine.is_editor_hint() and _detect_player:
		_activate( false ) # always start the level deactivated
		_update_map()
		_create_level_limits()

#----------------------------
# Update map
#----------------------------
func _update_map() -> void:
	if not _map:
		if _debug: print( name, ": Requires a valid single level map." )
		_set_LDtk_tilemaps_recursive( self )
		return
	if not _map.single_level:
		if _debug: print( name, ": Only supports single level maps." )
		_set_LDtk_tilemaps_recursive( self )
		return
	if _debug: print( name, ": Updating map" )
	level_name = _map.single_level_name
	rect = _map.world_data[ level_name ].level_rect
	if _map.entity_data[ level_name ].has( "entities" ):
		entities.assign( _map.entity_data[ level_name ].entities )
	_set_LDtk_tilemaps_recursive( self )

func _set_LDtk_tilemaps_recursive( node : Node ) -> void:
	for c in node.get_children():
		if c is LDtkTileMap:
			c._map = _map
		_set_LDtk_tilemaps_recursive( c )

#----------------------------
# Level Limits
#----------------------------
func force_level_limits()->void:
	if rect.size.x == 0 and rect.size.y == 0: return
	_level_limits_created = false
	if _detection_area:
		_detection_area.queue_free()
	_create_level_limits()
func _create_level_limits() -> void:
	if _level_limits_created: return
	if rect.size.x == 0 and rect.size.y == 0: return
	_level_limits_created = true
	var _ret : int
	_detection_area = Area2D.new()
	_detection_area.name = "_player_limits"
	_detection_area.collision_layer = 0
	_detection_area.collision_mask = _player_detection_mask
	#_detection_area.visible = false
	var _detection_area_shape = CollisionShape2D.new()
	_detection_area_shape.shape = RectangleShape2D.new()
	_detection_area_shape.shape.size = \
		Vector2( rect.size ) + Vector2.ONE * _detect_width * 2
	_detection_area_shape.position = rect.size * 0.5;
	_detection_area.body_exited.connect( _on_player_exited_detection_area, CONNECT_DEFERRED )
	add_child( _detection_area )
	_detection_area.add_child( _detection_area_shape )


func _on_detect_start_time():
	if _debug: print( name, ": Grace time terminated. Activating border areas")
	_activate_detection_areas( true )

func _on_player_exited_detection_area( player : Node2D ) -> void:
	# find player position with respect to level
	if player.global_position.x < 0:
		_report_player_detected( player, rect.position + \
			Vector2i( -_report_offset - _detect_margin, player.position.y ) )
	elif player.global_position.x > rect.size.x:
		_report_player_detected( player, rect.position + \
			Vector2i( rect.size.x + _report_offset + _detect_margin, player.position.y ) )
	elif player.global_position.y < 0:
		_report_player_detected( player, rect.position + \
			Vector2i( player.position.x, -_report_offset - _detect_margin ) )
	else:
		_report_player_detected( player, rect.position + \
			Vector2i( player.position.x, player.position.y + _report_offset + _detect_margin ) )

func _report_player_detected( player : Node2D, player_world_position : Vector2 ) -> void:
	if not _detect_player: return
	player_leaving_level.emit( player, player_world_position )


#-------------------------------------------
# Useful functions
#-------------------------------------------
func get_node_worldpos( node : Node2D ) -> Vector2i:
	return Vector2i( node.global_position ) + rect.position

func local_to_world_position( localpos : Vector2 ) -> Vector2i:
	return Vector2i( localpos ) + rect.position

func get_worldpos_px() -> Vector2i:
	if not _map: return Vector2i.ZERO
	return rect.position

func get_worldsize_px() -> Vector2i:
	if not _map: return Vector2i.ZERO
	return rect.size
	
func _activate_detection_areas( v : bool = true ) -> void:
	var p = not v
	if not _detection_area: return
	_detection_area.get_child(0).call_deferred( "set_disabled", p )

func get_entities() -> Array[Dictionary]:
	return entities


