class_name FlashSprite extends Sprite2D

var flash_timer : SceneTreeTimer

func _ready() -> void:
	material = preload( "flash_sprite.material" ).duplicate( true )

func flash( duration : float = 0.2 ) -> void:
	flash_timer = get_tree().create_timer( duration )
	flash_timer.timeout.connect( _on_flash_timer_finished )
	material.set_shader_parameter( "flash", true )

func stop() -> void:
	_on_flash_timer_finished()

func _on_flash_timer_finished() -> void:
	material.set_shader_parameter( "flash", false )
	flash_timer = null
