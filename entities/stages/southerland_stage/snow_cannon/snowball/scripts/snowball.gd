extends AnimatedSprite2D

var movement : float

func _on_area_2d_body_entered(player: Node2D) -> void:
	if player.name == "Player":
		player.snowball_hit()
		$SnowballHit.play()
		_hit()

	if player is TileMapLayer or player is TileMap:
		$SnowballHit.play()
		_hit()

func _process(_delta: float) -> void:
	if !GlobalScene.movement_enabled:
		movement = 0
		await get_tree().create_timer(.5).timeout
		queue_free()
		return
	position.x -= movement

	if position.x <= -1000 or position.x >= 1000:
		queue_free()


func _hit() -> void:
	movement = 0
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	play("explode")
	await animation_finished
	queue_free()


func setup(movement_speed : float, position_to_set : Vector2) -> void:
	movement = movement_speed
	position = position_to_set
	if movement_speed < 0:
		flip_h = false
