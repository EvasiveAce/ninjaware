extends AnimatedSprite2D

var is_player_active : bool = false
var is_shooting : bool = false
var preshot_timer : float = 2.0
var postshot_timer : float = 8.0
var shot_cooldown : bool = false

var snowball_scene = preload("res://entities/stages/southerland_stage/snow_cannon/snowball/scenes/snowball.tscn")

func _on_sight_line_body_entered(player: Node2D) -> void:
	print('hit?')
	if player.name == "Player":
		is_player_active = true

func _on_sight_line_body_exited(player: Node2D) -> void:
	if player.name == "Player":
		is_player_active = false
		$PreShotTimer.stop()


func _process(delta: float) -> void:
	print(is_player_active)
	if is_player_active and !is_shooting and !shot_cooldown:
		_shoot()
		print("shot")


func _shoot():
	if is_player_active:
		is_shooting = true
		$PreShotTimer.start(preshot_timer)

func _on_pre_shot_timer_timeout() -> void:
	if snowball_scene:
		is_shooting = false
		shot_cooldown = true
		play("Start")
		var snowball = snowball_scene.instantiate()
		$SnowballArray.add_child(snowball)
		$PostShotTimer.start(postshot_timer)
		await animation_finished
		play("Stop")

func _on_post_shot_timer_timeout() -> void:
	shot_cooldown = false


