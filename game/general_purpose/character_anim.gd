class_name CharacterAnim extends AnimationPlayer

var anim_cur : String
var anim_nxt : String

func update_anim() -> void:
	if anim_cur != anim_nxt:
		anim_cur = anim_nxt
		play( anim_cur )
