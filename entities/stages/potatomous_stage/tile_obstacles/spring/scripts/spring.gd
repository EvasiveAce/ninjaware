extends Node2D

func _on_area_2d_body_entered(player: Node2D, direction: String) -> void:
	if player.name == "Player":
		$SpringSprite.play("bounce")
		player.bounce_on_spring(direction)
		$Spring.play()
