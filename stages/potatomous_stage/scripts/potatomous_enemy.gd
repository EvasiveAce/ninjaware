extends Path2D

func _process(delta: float) -> void:
	if $PathFollow2D/Potatomous.is_playing():
		if name == "PotatomousEnemy1":
			$PathFollow2D.progress_ratio += .15 * delta
		elif name == "PotatomousEnemy2":
			$PathFollow2D.progress_ratio += .2 * delta
		else:
			$PathFollow2D.progress_ratio += .25 * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_parent().get_parent()._on_enemy_enter()
		$PathFollow2D/Potatomous.stop()
