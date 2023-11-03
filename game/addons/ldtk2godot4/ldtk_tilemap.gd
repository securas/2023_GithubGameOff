@tool
class_name LDtkTileMap extends TileMap

@export var _map : LDtkMap = null : set = _set_map
@export var __levels : Array[String] : set = _set_levels
@export var _layers : Array[String] : set = _set_layers
@export var tilemap_layer : int = 0
@export var tilemap_source_id : int = 0

var _debug := false
var _levels : Array[String]


#----------------------------
# Setters
#----------------------------
func _set_map( v : LDtkMap ) -> void:
	if _debug: print( name, ": Setting Map" )
	_map = v
#	if Engine.is_editor_hint() and name: _update_ldtk_map()
	_update_ldtk_map()

func _set_levels( v : Array[String] ) -> void:
	if _debug: print( name, ": Setting Levels" )
	_levels = v
	__levels = _levels
	if Engine.is_editor_hint() and name: _update_ldtk_map()
#	_update_ldtk_map()

func _set_layers( v : Array[String] ) -> void:
	if _debug: print( name, ": Setting Layers" )
	_layers = v
	if Engine.is_editor_hint() and name: _update_ldtk_map()
#	_update_ldtk_map()

#----------------------------
# Enter Tree
#----------------------------
func _enter_tree() -> void:
	if _debug: print( name, ": Entering tree" )
#	if Engine.is_editor_hint(): # Not sure about this
#		_update_ldtk_map()
	_update_ldtk_map()


#----------------------------
# Update Map
#----------------------------
func _update_ldtk_map() -> void:
	__update_ldtk_map()


func __update_ldtk_map() -> void:
	if _debug: print( name, ": Updating tilemap" )
	clear()
	if not _map:
		if _debug: print( name, ": No available LDtk map." )
		return
	if _map.single_level:
		if _debug: print( name, ": Single level map. Setting level to ", _map.single_level_name )
		_levels = [ _map.single_level_name ]
	if not _levels:
		if _debug: print( name, ": No levels defined." )
		return
	if not _layers:
		if _debug: print( name, ": No layers defined." )
		return
	
	for cur_level_name in _levels:
		if _debug: print( name, ": Updating level - ", cur_level_name )
		if not _map.cell_data.has( cur_level_name ):
			if _debug: print( name, ": Could not find data for level ", cur_level_name )
			continue
		var cur_level : Dictionary = _map.cell_data[ cur_level_name ]
		for cur_layer_name in _layers:
			if _debug: print( name, ": Updating layer - ", cur_layer_name )
			if not cur_level.has( cur_layer_name ):
				if _debug: print( name, ": Could not find data for layer ", cur_layer_name )
				continue
			var cur_layer : Dictionary = cur_level[ cur_layer_name ]
			_write_layer_to_map( cur_layer )

func _write_layer_to_map( cur_layer : Dictionary ) -> void:
	var ntiles : int = cur_layer.tilemap_position.size()
	if _debug: print( name, ": Setting ", ntiles," tiles." )
	for idx in range( ntiles ):
		set_cell(
			tilemap_layer,
			cur_layer.tilemap_position[idx],
			tilemap_source_id,
			cur_layer.autotile_coord[idx],
			0
		)
	


