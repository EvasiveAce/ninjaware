extends AnimatedSprite2D

var is_right_cannon : bool = false
var is_first_shot : bool = true


var snowball_scene = preload("res://entities/stages/southerland_stage/snow_cannon/snowball/scenes/snowball.tscn")


func _ready() -> void:
	if is_in_group("RightCannon"):
		is_right_cannon = true
	else:
		is_right_cannon = false


func _process(_delta: float) -> void:
	if !GlobalScene.movement_enabled:
		is_first_shot = true
		return
	if GlobalScene.movement_enabled and is_first_shot:
		is_first_shot = false
		await get_tree().create_timer(.1 / get_parent().get_parent().level_speed).timeout
		play("Start")
	if frame_progress == 1 and !is_first_shot and $SnowballArray.get_child_count() == 0:
		play("Start")

func _on_frame_changed() -> void:
	if animation == "Start" and GlobalScene.movement_enabled:
		if frame == 3:
			$ShotAudio.play()
			var snowball = snowball_scene.instantiate()
			var snowball_multiplier = 0.3

			var current_lvl_speed = get_parent().get_parent().level_speed

			if current_lvl_speed == 5.0: 
				snowball_multiplier = 0.55
			elif current_lvl_speed == 5.5: 
				snowball_multiplier = 0.40
			if is_right_cannon:
				snowball.setup(-snowball_multiplier * current_lvl_speed, Vector2(3, 0))
			else:
				snowball.setup(snowball_multiplier * current_lvl_speed, Vector2(-3, 0))
			$SnowballArray.add_child(snowball)
			await animation_finished
