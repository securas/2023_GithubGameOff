extends Node2DPassiveEntity

func _entity_initialize( params : Dictionary ) -> void:
	print( "water: ", params )
	$pixel.region_rect.size = params.size
