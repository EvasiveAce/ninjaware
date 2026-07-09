extends Node2D

var is_first_shot : bool = true

var snowball_scene = preload("res://entities/stages/southerland_stage/snow_cannon/snowball/scenes/snowball.tscn")
@onready var southerland = $SoutherlandSprite

func _on_southerland_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		$SoutherlandArea2D/SoutherlandCollisionShape2D.disabled = true
		get_parent().get_parent()._on_enemy_enter()

func _process(_delta: float) -> void:
	if !GlobalScene.movement_enabled:
		$SoutherlandArea2D/SoutherlandCollisionShape2D.disabled = true
		is_first_shot = true
		return
	
	$SoutherlandArea2D/SoutherlandCollisionShape2D.disabled = false

	if GlobalScene.movement_enabled and is_first_shot:
		is_first_shot = false
		await get_tree().create_timer(.075 / get_parent().get_parent().level_speed).timeout
		southerland.play("Start")
	if southerland.frame_progress == 1 and !is_first_shot and $SnowballArray.get_child_count() == 0:
		southerland.play("Start")

func _on_southerland_sprite_frame_changed() -> void:
	if $SoutherlandSprite.animation == "Start" and GlobalScene.movement_enabled:
		if $SoutherlandSprite.frame == 6:
			$ShotAudio.play()
			var snowball = snowball_scene.instantiate()
			snowball.setup(2.5, Vector2(-30,10))
			$SnowballArray.add_child(snowball)
			await $SoutherlandSprite.animation_finished
			$SoutherlandSprite.play("Stop")
