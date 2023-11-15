class_name EnemyEntity extends CharacterBody2DPassiveEntity

const GRAVITY = 900
const TERM_VEL = 200

var dir_cur : int
var dir_nxt : int
var position_offset : Vector2

func gravity( delta : float, multiplier : float = 1.0 ) -> void:
	velocity.y = min( velocity.y + multiplier * GRAVITY * delta, TERM_VEL )

func is_at_border( delta : float, check_back : bool = false ) -> bool:
	var gtrans = global_transform
	var tfall = test_move( \
		gtrans.translated( Vector2.RIGHT * 16 * dir_cur ), \
			Vector2.DOWN )
	if not tfall: return true
	if check_back:
		tfall = test_move( \
			gtrans.translated( Vector2.LEFT * 16 * dir_cur ), \
			Vector2.DOWN )
		if not tfall: return true
	# test wall
	var wall_vel = Vector2.RIGHT * dir_cur * 100 # cheating
	var wall = test_move( gtrans, wall_vel * delta )
	if wall: return true
	return false

func check_player( reach : float ) -> bool:
	return target_in_sight(
		global_position + position_offset,
		game.player.get_global_position_with_offset(),
		reach,
		dir_cur,
		0.7,
		[],
		1
	)


func target_in_sight( sourcepos : Vector2, targetpos : Vector2, \
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
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create( sourcepos, targetpos, colmask, exclude )
	var result = space_state.intersect_ray( query )
	if result.empty(): return true
#	print( "obstacle: ", result.collider.name )
	return false
