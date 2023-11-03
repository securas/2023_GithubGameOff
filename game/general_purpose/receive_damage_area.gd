class_name RcvDamageArea extends Area2D


@export var active : bool = true
var control_node = null

func _ready():
	var _ret : int = connect( "area_entered", self._on_deal_damage_area_entered )
	monitorable = false
	monitoring = true
	if not control_node:
		control_node = get_parent()


func _on_deal_damage_area_entered( area ):
	if not active: return
	if not area is DealDamageArea:
		printerr( name, ": Failed to interact with non DealDamageArea" )
		return
	
	# alert parent immediately about damage
	if control_node and control_node.has_method( "_on_receiving_damage" ):
		control_node._on_receiving_damage( area.control_node, area.damage_dealt )
	
	# report interaction to dealdamagearea
	area._on_dealing_damage( self )

