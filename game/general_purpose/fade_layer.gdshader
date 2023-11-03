shader_type canvas_item;
uniform int type = 9;
uniform float r = 1.0;

void fragment()
{
	const vec3 color0 = vec3( 0.0, 0.0, 0.0 );
    if( type == 0 )
    {
        COLOR = vec4( color0, step( UV.x, r ) );
    }
    else if( type == 1 )
    {
        COLOR = vec4( color0, step( UV.y, r ) );
    }
    else if( type == 2 )
    {
        COLOR = vec4( color0, step( 1.0 - r, abs( UV.x - 0.5 ) ) );
    }
    else if( type == 3 )
    {
        COLOR = vec4( color0, step( 1.0 - r, abs( UV.y - 0.5 ) ) );
    }
    else if( type == 4 )
    {
        float d = length( UV * vec2( 1.77778, 1.0 ) - vec2( 0.88889, 0.5 ) );
        COLOR = vec4( color0, step( r, d ) );
    }
    else if( type == 5 )
    {
        COLOR = vec4( color0, step( mod( UV.x * 20.0, 1.0 ) + UV.x, r * 2.0 ) );
    }
    else if( type == 6 )
    {
        COLOR = vec4( color0, step( mod( ( UV.x + UV.y * 0.5625 ) * 10.0, 1.0 ) + UV.y + UV.x, r * 3.0 ) );
    }
    else if( type == 7 )
    {
        vec2 uv = mod( UV * vec2( 1.77778, 1.0 ) * 10.0, 1.0 );
        float d = length( uv - vec2( 0.5, 0.5 ) );
        COLOR = vec4( color0, step( 1.0 - r, d ) );
    }
    else if( type == 8 )
    {
        COLOR = vec4( color0, step( 1.0 - r, abs( UV.x + abs( UV.y - 0.5 ) - 0.75 ) ) );
    }
    else if( type == 9 )
    {
        vec2 uv = UV - vec2( 0.5 );
        float a = atan( uv.x / uv.y );
        COLOR = vec4( color0, step( 1.0 - r, mod( a * 3.1415, 1.0 ) ) );
    }
}