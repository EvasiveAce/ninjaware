extends AnimatedSprite2D

## Portal enter body function.
## [br] Signal connected from [EndPointArea2D]
func _on_end_point_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		stop()
		get_parent().get_parent().portal_entered()
