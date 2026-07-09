extends Node2D

var is_flying : bool = false
var inital_speed : float = 0.0
var max_speed : float = 1.0
var accel_speed : float = 0.005

func _ready():
	await get_tree().create_timer(2.5).timeout
	is_flying = true
	_explode()

func _process(_delta: float) -> void:
	if is_flying:
		$RocketSoundPlayer.play()
		inital_speed = 1.0
		position.y -= inital_speed

func _explode() -> void:
	print('hit?')

	await get_tree().create_timer(4.25).timeout
	is_flying = false

	$RocketSprite.visible = false
	$ExplodeSprite.visible = true
	$ExplodeSprite.play("default")
