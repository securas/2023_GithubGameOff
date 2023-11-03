@tool
extends EditorPlugin

var ldtk2godot4_import

func _enter_tree():
	ldtk2godot4_import = preload( "ldtk2godot4_import.gd" ).new()
	add_import_plugin( ldtk2godot4_import )


func _exit_tree():
	remove_import_plugin( ldtk2godot4_import )
	ldtk2godot4_import = null



