class_name DealDamageArea extends Area2D


@export var damage_dealt : int = 1
var control_node = null

func _ready():
	monitorable = true
	monitoring = false
	if not control_node:
		control_node = get_parent()

func _on_dealing_damage( area ):
	if control_node and control_node.has_method( "_on_dealing_damage" ):
		control_node._on_dealing_damage( area.control_node )
