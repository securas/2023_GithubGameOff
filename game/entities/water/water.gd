extends Node2DPassiveEntity

func _entity_initialize( params : Dictionary ) -> void:
	$pixel.region_rect.size = params.size
