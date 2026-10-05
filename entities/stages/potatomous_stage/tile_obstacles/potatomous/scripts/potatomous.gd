extends Node2D

func _process(delta: float) -> void:
	if $Path2D/PathFollow2D/PotatomousSprite.is_playing():
		if name == "PotatomousEnemy1":
			$Path2D/PathFollow2D.progress_ratio += .12 * delta
		elif name == "PotatomousEnemy2":
			$Path2D/PathFollow2D.progress_ratio += .16 * delta
		else:
			$Path2D/PathFollow2D.progress_ratio += .21 * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_parent().get_parent().get_parent()._on_enemy_enter()
		$Path2D/PathFollow2D/PotatomousSprite.stop()
