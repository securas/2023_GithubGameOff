@tool
extends Node2D

@export var map : LDtkMap


func _enter_tree() -> void:
	if not Engine.is_editor_hint(): return
	for c in get_children():
		c.queue_free()
	if map:
		print( map.world_data )
		print( map.resource_path )
		var pos = map.resource_path.find( ".ldtk" )
		var png_path = map.resource_path.substr( 0, pos ) + "/png"
		var _levels = map.world_data.keys()
		for level_name in map.world_data.keys():
			var png_filename = "%s/%s.png" % [ png_path, level_name ]
			var texture = load( png_filename )
			var s = Sprite2D.new()
			s.texture = texture
			s.position = map.world_data[level_name].level_rect.position
			s.centered = false
			add_child( s )

func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()



#func _enter_tree() -> void:
	#if not Engine.is_editor_hint(): return
	#print( "Updating map images" )
	#for c in get_children():
		#c.queue_free()
	#var world = LDtkWorldData.new( preload( "res://ldtk/maps.ldtk" ) )._world as Dictionary
	#var rooms = world.keys()
	#for r in rooms:
		#var texturefile = "%s/%s.png" % [ PNGPATH, r ]
		#var texture = load( texturefile )
		#var s := Sprite.new()
		#s.texture = texture
		#s.position = world[ r ].level_rect.position
		#s.centered = false
		#add_child( s )
