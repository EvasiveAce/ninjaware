extends AnimatedSprite2D

var is_player_active : bool = false
var shot_timer : float = 3.0
var is_right_cannon : bool = false
var is_first_shot : bool


var snowball_scene = preload("res://entities/stages/southerland_stage/snow_cannon/snowball/scenes/snowball.tscn")


func _ready() -> void:
	if is_in_group("RightCannon"):
		is_right_cannon = true
	else:
		is_right_cannon = false

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
		if is_first_shot:
			is_first_shot = false
			_on_shot_timer_timeout()
		else:
			$ShotTimer.start(shot_timer)


func _on_shot_timer_timeout() -> void:
	if !is_player_active:
		return

	play("Start")
	$ShotAudio.play()

	var snowball = snowball_scene.instantiate()

	if is_right_cannon:
		snowball.setup(-2.5, Vector2(3, -6))
	else:
		snowball.setup(2.5, Vector2(-3, -6))
	
	$SnowballArray.add_child(snowball)

	await animation_finished
	play("Stop")
