extends Sprite2D


@onready var smoke: AnimatedSprite2D = $Smoke


func _ready() -> void:
	# Keeps the blue marker visible in the editor but hides it in-game.
	texture = null

	smoke.visible = false
	smoke.animation_finished.connect(_on_smoke_finished)


func play_spawn() -> void:
	smoke.stop()
	smoke.frame = 0
	smoke.visible = true
	smoke.play("Smoke")
	$AudioPlayer.play()


func _on_smoke_finished() -> void:
	smoke.visible = false