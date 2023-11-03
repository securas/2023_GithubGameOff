shader_type canvas_item;

void fragment()
{
	const float fps = 4.0;
	const float frame_count = 4.0;
	const float cell_size = 10.0;
	
	float frame = floor( fract( TIME * fps / frame_count ) * frame_count );
	vec2 uv = UV;// + vec2( frame * cell_size, 0.0 ) * TEXTURE_PIXEL_SIZE;
	if( uv.y < 9.0 * cell_size * TEXTURE_PIXEL_SIZE.y )
		uv.x += frame * cell_size * TEXTURE_PIXEL_SIZE.x;
	COLOR = texture( TEXTURE, uv );
}