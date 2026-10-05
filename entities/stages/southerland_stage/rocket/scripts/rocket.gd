extends Node2D

var is_flying : bool = false
var inital_speed : float = 0.0
var max_speed : float = 1.0
var accel_speed : float = 0.005


func _on_rocket_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_parent().get_parent().rocket_enter()
		is_flying = true
		$RocketPlayer.play()
		await get_tree().create_timer(.25).timeout
		$ExplodeSprite.visible = true
		$ExplodeSprite.play("default")

func _process(_delta: float) -> void:
	if is_flying:
		$RocketSoundPlayer.play()
		inital_speed = min(inital_speed + accel_speed, max_speed)
		$RocketSprite.position.y -= inital_speed