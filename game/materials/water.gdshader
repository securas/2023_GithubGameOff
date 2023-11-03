shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

void fragment()
{
	const float speed = 3.0;//2.0;
	//const vec4 water_color = vec4( 0.1, 0.1, 0.25, 1.0 );//vec4( 0.2, 0.2, 0.5, 1.0 ); //
	const vec4 water_color = vec4( 0.1, 0.1, 0.1, 1.0 );
	
	
	// compute ration between the screen uv and the texture uv
	vec2 tex_to_screen_uv_ratio = -SCREEN_PIXEL_SIZE / TEXTURE_PIXEL_SIZE;
	
	// compute UV of the flipped screen
	//vec2 flipped_screen_uv = vec2( SCREEN_UV.x, 
		//SCREEN_UV.y + 2.0 * UV.y * tex_to_screen_uv_ratio.y );
	vec2 suv = vec2( SCREEN_UV.x, SCREEN_UV.y + 2.0 * UV.y * tex_to_screen_uv_ratio.y );
	suv.x += 0.125 * SCREEN_PIXEL_SIZE.x * sin( 100.0 * UV.y  + speed * TIME ) * UV.y;
	
	suv = floor( suv / SCREEN_PIXEL_SIZE ) * SCREEN_PIXEL_SIZE;
	suv += SCREEN_PIXEL_SIZE * 0.5;
	
	vec4 c1 = textureLod( SCREEN_TEXTURE, suv, 0.0 );
	c1 = mix( c1, water_color, 0.1 );
	
	//c1 = textureLod( SCREEN_TEXTURE, SCREEN_UV + vec2(0.1), 0.0 );
	COLOR = c1;
}