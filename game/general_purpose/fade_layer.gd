extends CanvasLayer

signal fade_complete

@export_color_no_alpha var pixel_color := Color.BLACK
@export_range( 0, 9 ) var transition_type : int = 0


var pixel : Sprite2D

func _ready() -> void:
	_create_fade()

func _create_fade() -> void:
	var img = Image.create( 1, 1, false, Image.FORMAT_RGBA8 )
	img.set_pixel( 0, 0, pixel_color )
	pixel = Sprite2D.new()
	pixel.texture = ImageTexture.create_from_image( img )
	pixel.scale = get_viewport().get_visible_rect().size
	pixel.centered = false
	pixel.material = preload( "./fade_layer.material" )
	pixel.modulate = pixel_color
	add_child( pixel )

func fade_in( instant : bool = false ) -> void:
	pixel.material.set_shader_parameter( "type", transition_type )
	if instant:
		pixel.material.set_shader_parameter( "r", 0.0 )
		return
	var fade_tween : Tween = create_tween()
	fade_tween.tween_method( _set_fade, \
		pixel.material.get_shader_parameter( "r" ), 0.0, 0.3 )
	fade_tween.finished.connect( _on_fade_finished )

func fade_out( instant : bool = false ) -> void:
	pixel.material.set_shader_parameter( "type", transition_type )
	if instant:
		pixel.material.set_shader_parameter( "r", 1.0 )
		return
	var fade_tween : Tween = create_tween()
	fade_tween.tween_method( _set_fade, \
		pixel.material.get_shader_parameter( "r" ), 1.0, 0.3 )
	fade_tween.finished.connect( _on_fade_finished )
#
func _on_fade_finished() -> void:
	fade_complete.emit()
#
func _set_fade( r : float ) -> void:
	pixel.material.set_shader_parameter( "r", r )
