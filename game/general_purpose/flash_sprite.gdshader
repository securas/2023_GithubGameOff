shader_type canvas_item;

uniform bool flash = false;
uniform float speed = 10.0;

void fragment()
{
	if( flash )
	{
		if( fract( TIME * speed ) > 0.5 )
			COLOR = vec4( 1.0, 1.0, 1.0, textureLod( TEXTURE, UV, 0.0 ).a );
	}
}


