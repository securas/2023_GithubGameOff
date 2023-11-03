@tool
extends EditorImportPlugin

enum Presets { DEFAULT }

var debug := true

func _get_importer_name() -> String:
	return "LDtk2Godot4"

func _get_visible_name() -> String:
	return "LDtk_Map"

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray( [ "ldtk", "ldtkl" ] )

func _get_save_extension() -> String:
	return "res"

func _get_resource_type() -> String:
	return "Resource"

func _get_preset_count() -> int:
	return Presets.size()

func _get_preset_name( idx : int ) -> String:
	match idx:
		Presets.DEFAULT:
			return "default"
		_:
			return "Unknown"

func _get_import_options( _path : String, _preset_idx : int ) -> Array[Dictionary]:
	return []

func _get_option_visibility( _path : String, _option_name : StringName, _options : Dictionary) -> bool:
	return true

func _get_priority() -> float:
	return 1.0

func _get_import_order() -> int:
	return 0

func _import( source_file : String, save_path : String, _options : Dictionary, _platform_variants : Array[String], _gen_files : Array[ String ] ) -> Error:
	if debug: print( "importing %s" % [ source_file ] )
	
	# read json data from file
	var file := FileAccess.open( source_file, FileAccess.READ )
	var json_string : String = file.get_as_text()
	file.close()
	file = null

	# parse json
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		print( "LDtk Import: JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line() )
		return error

	var ldtkmap = LDtkMap.new()
	ldtkmap.single_level = not json.data.has( "levels" )
	if ldtkmap.single_level: ldtkmap.single_level_name = json.data.identifier
	ldtkmap.cell_data = _process_json_celldata( json.data ).duplicate( true )
	ldtkmap.entity_data = _process_json_entities( json.data ).duplicate( true )
	ldtkmap.world_data = _process_json_leveldata( json.data ).duplicate( true )

	var filename = save_path + "." + _get_save_extension()
#	print( "importer levels: ", ldtkmap.cell_data )
	return ResourceSaver.save( ldtkmap, filename )


func _process_json_leveldata( json : Dictionary ) -> Dictionary:
	var data := {}
	var json_levels = []
	if json.has( "levels" ):
		json_levels = json.levels
	else:
		# this is a partial level file
		json_levels = [json]
	for source_level in json_levels:
		data[source_level.identifier] = {}
		data[source_level.identifier]["level_rect"] = Rect2(
			Vector2( source_level.worldX, source_level.worldY ),
			Vector2( source_level.pxWid, source_level.pxHei )
		)
		data[source_level.identifier]["external_resource"] = source_level.externalRelPath
	
	return data

func _process_json_celldata( json : Dictionary ) -> Dictionary:
#	print( " <<<< Importing LDtk Data >>>>")
	var data := {}
	var json_levels = []
	if json.has( "levels" ):
		# a full levels LDtk file
		json_levels = json.levels
	else:
		# this is a partial level file
		json_levels = [json]
	
	for source_level in json_levels:
		if source_level.has( "externalRelPath" ) and source_level.externalRelPath:
			print( "Cells: This level is under a different file..." )
			continue
		
		data[source_level.identifier] = {}
		for source_layer in source_level.layerInstances:
			if source_layer.__type == "Entities": continue
			data[source_level.identifier][source_layer.__identifier] = {}
			data[source_level.identifier][source_layer.__identifier].cell_size = source_layer.__gridSize
			var tilemap_position = PackedVector2Array()
			var autotile_coord = PackedVector2Array()
			var flip_x : Array[bool] = []
			var flip_y : Array[bool]= []
			var transpose : Array[bool] = []
			
			var cell_size = source_layer.__gridSize
			
			var source_layer_tiles = source_layer.autoLayerTiles
			if not source_layer_tiles: source_layer_tiles = source_layer.gridTiles
			for source_cell in source_layer_tiles:#source_layer.autoLayerTiles:
				tilemap_position.append( Vector2( source_cell.px[0] / cell_size, source_cell.px[1] / cell_size ) )
				autotile_coord.append( Vector2( source_cell.src[0], source_cell.src[1] ) / cell_size )
				flip_x.append( int( source_cell.f ) & 1 == 1 )
				flip_y.append( int( source_cell.f ) & 2 == 2 )
				transpose.append( false )
			data[source_level.identifier][source_layer.__identifier].tilemap_position = tilemap_position
			data[source_level.identifier][source_layer.__identifier].autotile_coord = autotile_coord
			data[source_level.identifier][source_layer.__identifier].flip_x = flip_x
			data[source_level.identifier][source_layer.__identifier].flip_y = flip_y
			data[source_level.identifier][source_layer.__identifier].transpose = transpose
	return data




func _process_json_entities( json : Dictionary ) -> Dictionary:
	var data := {} 
	
	var json_levels = []
	if json.has( "levels" ):
		json_levels = json.levels
	else:
		json_levels = [json]
	
	for source_level in json_levels:
		if source_level.has( "externalRelPath" ) and source_level.externalRelPath:
			if debug: print( "Entities: This level is under a different file..." )
			continue
		data[source_level.identifier] = {}
		for source_layer in source_level.layerInstances:
			if source_layer.__type != "Entities": continue
			data[source_level.identifier][source_layer.__identifier] = []
			var cell_size : int = source_layer.__gridSize
			var layer_defid = source_layer.layerDefUid
			for entity in source_layer.entityInstances:
				var new_entity : Dictionary
				new_entity.id = entity.__identifier
				new_entity.position_px = Vector2( entity.px[0], entity.px[1] )
				new_entity.iid = entity.iid
				new_entity.size = Vector2( entity.width, entity.height )
				new_entity.parameters = {}
				for parameter in entity.fieldInstances:
					new_entity.parameters[parameter.__identifier] = parameter.__value
				data[source_level.identifier][source_layer.__identifier].append( new_entity )
	return data
