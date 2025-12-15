extends AnimatedSprite2D

func _on_area_2d_body_entered(player: Node2D) -> void:
    if player.name == "Player":
        play('default')
        player.bounce_on_potato_bomb_left_facing()
