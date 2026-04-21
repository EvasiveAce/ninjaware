extends Node2D

#region -- Setup --
## Array to keep laughing markers.
var markers_array : Array
## Current markers array index
var current_markers_array_index : int = 0
## Time between laughing.
var time : float = .35
## NumberLabel Int
var lvlToUse : int = 0

## String of current enemy
var enemy_to_use : String
var enemy_sprite : AnimatedSprite2D
#endregion

#region -- Node Setup --
@onready var player_hp_container = $TransitionSprite/PlayerHPContainer
@onready var enemy_hp_container = $TransitionSprite/EnemyHPContainer
#endregion

func _ready() -> void:
	enemy_to_use = get_parent().current_enemy
	match enemy_to_use:
		"Dummy":
			enemy_sprite = $TransitionSprite/EnemyContainer/DummyAnimatedSprite
		"Potatomous":
			enemy_sprite = $TransitionSprite/EnemyContainer/PotatomousAnimatedSprite
		"Southerland":
			enemy_sprite = $TransitionSprite/EnemyContainer/SoutherlandAnimatedSprite
	
	enemy_sprite.visible = true
	markers_array = enemy_sprite.get_children()
	enemy_sprite.play("idle")

## Used to get parent to change a tiny bit earlier than in code
## [br] Used in [TransitionIn].
func _start_audio():
	get_parent().child_update_audio()

func _stop_audio():
	get_parent().child_stop_audio()

func _begin_audio():
	get_parent().child_begin_audio()

func _reset_level():
	lvlToUse = 0

func _get_current_level():
	lvlToUse += 1
	if lvlToUse <= 9:
		$TransitionSprite/LevelNode/NumberLabel.text = "0" + str(lvlToUse)
	else:
		$TransitionSprite/LevelNode/NumberLabel.text = str(lvlToUse)

func _lose_current_level():
	var target_level : int = 1
	if lvlToUse >= 9:
		target_level = 9
	elif lvlToUse >= 5:
		target_level = 5
	else:
		target_level = 1
	
	while lvlToUse > target_level:
		lvlToUse -= 1
		
		if lvlToUse <= 9:
			$TransitionSprite/LevelNode/NumberLabel.text = "0" + str(lvlToUse)
		else:
			$TransitionSprite/LevelNode/NumberLabel.text = str(lvlToUse)
		
		$LostLevel.play() 
		
		await get_tree().create_timer(0.5).timeout 


func _call_parent_tally() -> void:
	get_parent()._tally_extra_lives()

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
	enemy_sprite.play("laugh")
	%LaughTimer.wait_time = time
	%LaughTimer.start()
	_switch_marker(markers_array[current_markers_array_index])


## Stops the enemy laugh cycle.
## [br] Used in [ReviveLevel].
func _enemy_laughing_stop() -> void:
	enemy_sprite.play("idle")
	$%LaughTimer.stop()


func _enemy_hit() -> void:
	enemy_sprite.play("hit")
	await enemy_sprite.animation_finished
	enemy_sprite.play("idle")
