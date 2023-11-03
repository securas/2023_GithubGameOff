class_name LDtkMap extends Resource

# Note: All variables to be saved have to be exported!
@export var single_level := false
@export var single_level_name : String
@export var world_data : Dictionary
@export var cell_data : Dictionary
@export var entity_data : Dictionary


#-------------------------------------------
# Useful functions
#-------------------------------------------
func get_level_names() -> PackedStringArray:
	return PackedStringArray( world_data.keys() )

func get_level_name_at( world_position : Vector2 ) -> StringName:
	for level_name in get_level_names():
		var r = world_data[level_name].level_rect as Rect2
		if r.has_point( world_position ):
			return StringName( level_name )
	return &""

func get_level_data( level_name : String ) -> Dictionary:
	if single_level:
		return world_data[ single_level_name ]
	if world_data.has( level_name ):
		return world_data[ level_name ]
	return {}


