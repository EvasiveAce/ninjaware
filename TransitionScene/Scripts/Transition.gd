extends Node2D

var markersArray := []
var currentArrayIndex := 0
var time := .35

func _ready():
	markersArray = [$TransitionSprite/EnemySprite/Marker2D, $TransitionSprite/EnemySprite/Marker2D2, $TransitionSprite/EnemySprite/Marker2D3]

func _lose_health() -> void:
	$TransitionSprite/HPContainer.get_child(0).visible = false
	await get_tree().create_timer(0.1).timeout
	$TransitionSprite/HPContainer.get_child(0).visible = true
	await get_tree().create_timer(0.1).timeout
	$TransitionSprite/HPContainer.get_child(0).queue_free()



func _enemy_laughing() -> void:
	%LaughTimer.wait_time = time
	%LaughTimer.start()
	_switch_marker(markersArray[currentArrayIndex])


func _switch_marker(marker : Marker2D) -> void:
	var textOffset = Vector2(
		randf_range(-32.0, 32.0),
		randf_range(-32.0, 32.0)
	)
	var randomPosition = marker.global_position + textOffset
	print(randomPosition)
	PopupText.display_text("HAHA", randomPosition, 32, 4)

func _on_laugh_timer_timeout() -> void:
	currentArrayIndex = (currentArrayIndex + 1) % markersArray.size()
	%LaughTimer.wait_time = time
	%LaughTimer.start()
	_switch_marker(markersArray[currentArrayIndex])
