extends Node2D

#region -- Setup --
## Array to keep laughing markers.
@onready var markers_array : Array = [$TransitionSprite/EnemySprite/Marker2D, $TransitionSprite/EnemySprite/Marker2D2, $TransitionSprite/EnemySprite/Marker2D3]
## Current markers array index
var current_markers_array_index : int = 0
## Time between laughing.
var time : float = .35
#endregion

#region -- Node Setup --
@onready var player_hp_container = $TransitionSprite/PlayerHPContainer
@onready var enemy_hp_container = $TransitionSprite/EnemyHPContainer
#endregion


## Removes player health from [player_hp_container].
## [br] Used in [PlayerHitAugh], [PlayerHitOuch], [GameOver].
func _lose_player_health() -> void:
	player_hp_container.get_child(0).visible = false
	await get_tree().create_timer(0.1).timeout
	player_hp_container.get_child(0).visible = true
	await get_tree().create_timer(0.1).timeout
	player_hp_container.get_child(0).queue_free()


## Removes enemey health from [enemy_hp_container].
## [br] Used in [DummyDeath], [DummyHit], [DummyHitSecond].
func _lose_enemy_health() -> void:
	enemy_hp_container.get_child(0).visible = false
	await get_tree().create_timer(0.1).timeout
	enemy_hp_container.get_child(0).visible = true
	await get_tree().create_timer(0.1).timeout
	enemy_hp_container.get_child(0).queue_free()


## Switches the laugh marker between the [markers_array] points.
## [br] Uses [PopupText] to display the text at the [random_laugh_position].
func _switch_marker(marker : Marker2D) -> void:
	var laugh_offset = Vector2(
		randf_range(-32.0, 32.0),
		randf_range(-32.0, 32.0)
	)
	var random_laugh_position = marker.global_position + laugh_offset
	PopupText.display_text("HAHA", random_laugh_position, 32, 4)


## Changes the current index for the laugh marker.
## [br] Signal connected from [LaughTimer].
func _on_laugh_timer_timeout() -> void:
	current_markers_array_index = (current_markers_array_index + 1) % markers_array.size()
	%LaughTimer.wait_time = time
	%LaughTimer.start()
	_switch_marker(markers_array[current_markers_array_index])


## Starts the enemy laugh cycle.
## [br] Used in [GameOver].
func _enemy_laughing() -> void:
	%LaughTimer.wait_time = time
	%LaughTimer.start()
	_switch_marker(markers_array[current_markers_array_index])


## Stops the enemy laugh cycle.
## [br] Used in [ReviveLevel].
func _enemy_laughing_stop() -> void:
	$%LaughTimer.stop()