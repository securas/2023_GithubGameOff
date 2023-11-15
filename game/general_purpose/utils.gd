class_name Utils extends RefCounted


static func on_screen( obj, margin : float = 16.0 ):
	var screen_rect = obj.get_viewport_rect()
	screen_rect.position -= Vector2.ONE * margin
	screen_rect.size += Vector2.ONE * margin * 2.0
	var screen_pos = screen_position( obj )
	return screen_rect.has_point( screen_pos )

static func screen_position( obj ) -> Vector2:
	return obj.get_global_transform_with_canvas().origin

static func get_unique_id( obj ) -> String:
	var id = obj.owner.filename + "_" + obj.owner.get_path_to( obj )
	return id

static func load_encrypted_file( filename : String ) -> Dictionary:
	#var f = File.new()
	#if f.file_exists( filename ):
		#var err = f.open_encrypted_with_pass( \
			#filename, File.READ, OS.get_unique_id() )
##		var err = f.open( \
##			filename, File.READ )
		#if err != OK:
			#f.close()
			#return err
		#var data = f.get_var( true )
		#f.close()
		#return data
	return {}

static func save_encrypted_file( filename : String, data : Dictionary ) -> bool:
	#var f := File.new()
	#var err := f.open_encrypted_with_pass( \
		#filename, File.WRITE, OS.get_unique_id() )
##	var err := f.open( \
##		filename, File.WRITE )
	#if err == OK:
		#f.store_var( data, true )
		#f.close()
		#return true
	#else:
		#f.close()
	return false

#func _target_in_sight( max_dist : float = 150.0, max_ratio : float = 0.2, self_offset : Vector2 = Vector2( 0, -6 ) ) -> bool:
static func target_in_sight( sourcenode : Node2D, sourcepos : Vector2, targetpos : Vector2, \
		max_dist : float, view_direction : float, view_angle : float, exclude : Array, colmask : int ) -> bool:
	var dist = targetpos - sourcepos
	# check maximum distance
	if max_dist > 0 and dist.length() > max_dist:
		return false
	# check if direction dependent view in the horizontal axis
	if abs( dist.x ) > 0.0 and abs( view_direction) > 0.0:
		if sign( dist.x ) != sign( view_direction ):
			return false
		# if there is a view direction, then also checks the view angle
		if abs( dist.angle_to( Vector2.RIGHT * sign( dist.x ) ) ) > view_angle:
			return false
	# check the view angle
	var space_state = sourcenode.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create( sourcepos, targetpos, colmask, exclude )

	var result = space_state.intersect_ray( query )
	if result.empty(): return true
#	print( "obstacle: ", result.collider.name )
	return false
