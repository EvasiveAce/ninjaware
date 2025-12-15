extends Sprite2D

## Spike enter body function.
## [br] Signal connected from [SpikeArea2D]
func _on_spike_area_2d_body_entered(player: Node2D) -> void:
    if player.name == "Player":
        player.enter_spike()