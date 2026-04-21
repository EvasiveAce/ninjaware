extends Node2D

var is_player_active : bool = false
var shot_timer : float = 3.0
var is_right_cannon : bool = false
var is_first_shot : bool



var snowball_scene = preload("res://entities/stages/southerland_stage/snow_cannon/snowball/scenes/snowball.tscn")

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	$SoutherlandArea2D/SoutherlandCollisionShape2D.disabled = false


func _on_southerland_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_parent().get_parent()._on_enemy_enter()


func _on_sight_line_body_entered(player: Node2D) -> void:
	if player.name == "Player":
		is_player_active = true
		is_first_shot = true

func _on_sight_line_body_exited(player: Node2D) -> void:
	if player.name == "Player":
		is_player_active = false
		$ShotTimer.stop()


func _process(_delta: float) -> void:
	if is_player_active and $ShotTimer.is_stopped():
		$ShotTimer.start(shot_timer)

func _on_shot_timer_timeout() -> void:
	if !is_player_active:
		return
	
	$SoutherlandSprite.play("Start")
	$ShotAudio.play()

func _on_southerland_sprite_frame_changed() -> void:
	if $SoutherlandSprite.animation == "Start":
		if $SoutherlandSprite.frame == 6:
			$ShotAudio.play()
			var snowball = snowball_scene.instantiate()
			snowball.setup(2.5, Vector2(-30,10))
			$SnowballArray.add_child(snowball)
			await $SoutherlandSprite.animation_finished
			$SoutherlandSprite.play("Stop")
