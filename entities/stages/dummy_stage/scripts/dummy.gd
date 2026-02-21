extends Sprite2D

func _ready() -> void:
    await get_tree().create_timer(1.0).timeout
    $DummyArea2D/DummyCollisionShape2D.disabled = false

func _on_dummy_area_2d_body_entered(body: Node2D) -> void:
    if body.is_in_group("Player"):
        get_parent().get_parent()._on_enemy_enter()
