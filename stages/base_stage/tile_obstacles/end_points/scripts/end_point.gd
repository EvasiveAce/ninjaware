extends AnimatedSprite2D

## Portal enter body function.
## [br] Signal connected from [EndPointArea2D]
func _on_end_point_area_2d_body_entered(_body: Node2D) -> void:
	get_parent().get_parent().portal_entered()