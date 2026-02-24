extends Node2D
## Base stage used by all stages.
class_name BaseStage


#region -- HP Setup --
@export_group("Player HP Setup")
## The amount of HP the player starts with.
@export_range(1, 100) var player_hp : int = 3
## The player HP texture scene.
@export var player_hp_entity : PackedScene

@export_group("Enemy HP Setup")
## The amount of HP the enemy starts with. 
## [br] [4 levels per 1 HP]
@export_range(1, 5) var enemy_hp : int = 3
## The enemy HP texture scene.
@export var enemy_hp_entity : PackedScene
#endregion

#region -- Level/Player Setup --
## The current level in the stage.
static var current_level : int
## The queue of levels.
## [br] [Level 1 - Level 12]
static var array_of_levels : Array[Node]
## The player on ready for shortcut.
@onready var player : Player = $Player
## The player's [AnimationTree].
@onready var player_tree : AnimationTree = $Player/AnimationTree
## Timer for the stage.
@onready var timer : Timer = $Timer
## Progress bar for the timer progression.
@onready var progress_bar : ProgressBar = $ProgressBar

@export_group("Level Setup")
## The level timer in seconds.
## [br] [Default for levels 1 - 4]
@export_range(1, 100) var level_speed : float = 6.0
## Default for game overs
var level_speed_default : float
var player_speed_default : float
#endregion

#region -- Transition Setup --
## The transition scene animation tree.
## [br] Used for the [animation_finished] signal.
# TODO: Update for level 
@onready var anim_tree = $TransitionUI/DummyAnimationTree
## State machine for the animation tree playback.
## [br] Used for most animations. 
@onready var state_machine = anim_tree.get("parameters/playback")
## Player HP Container for losing/adding health.
@onready var player_hp_container = $TransitionUI/TransitionSprite/PlayerHPContainer
## Enemy HP Container for losing/adding health.
@onready var enemy_hp_container = $TransitionUI/TransitionSprite/EnemyHPContainer
#endregion


func _ready() -> void:
	level_speed_default = level_speed
	player_speed_default = player.speed_factor
	await _health_set_up(false)


func _process(_delta: float) -> void:
	progress_bar.value = timer.time_left
	_player_out_of_bounds()
	_check_for_coin()


## Checks to see if player is out of bounds, and emits [timeout] if so.
func _player_out_of_bounds():
	if player.position.y >= 950:
		player.position.y = -1000
		timer.stop()
		timer.emit_signal('timeout')


## Checks to see if [current_state] is [InsertCoin], [ui_accept] is pressed, and revives if so.
func _check_for_coin():
	if state_machine:
		var current_state = state_machine.get_current_node()
		if current_state == "InsertCoin":
			if Input.is_action_just_pressed('ui_accept'):
				await _revive_animation()
				await _health_set_up(true)


## Sets up the health for both the player and enemy.
## [br] If [revival], includes additional animation.
func _health_set_up(revival : bool):
	_stop_scene()
	player.reset_momentum()
	level_speed = level_speed_default
	player.speed_factor = player_speed_default
	_arrays_reset()
	for hp in player_hp:
		await get_tree().create_timer(0.1).timeout
		player_hp_container.add_child(player_hp_entity.instantiate())
		$TransitionUI/LivesAdded.play()

	var enemy_hp_difference = enemy_hp_container.get_child_count()
	if !revival:
		await _battle_start()
	else:
		await _battle_revive()

	for hp in (enemy_hp - enemy_hp_difference):
		await get_tree().create_timer(0.1).timeout
		enemy_hp_container.add_child(enemy_hp_entity.instantiate())
		$TransitionUI/LivesEnemyAdded.play()

	player.reset_momentum()
	player.position = _find_start_point()
	array_of_levels[current_level].enabled = true

	await _battle_intro()
	timer.start(level_speed)
	progress_bar.max_value = timer.wait_time
	await _battle_transition_in()

	_start_scene()


## Resets the level array after Game Over or inital HP setup.
func _arrays_reset():
	array_of_levels = []
	current_level = 0
	$Level1.enabled = false
	$Level2.enabled = false
	$Level3.enabled = false
	$Level4.enabled = false
	$Level5.enabled = false
	$Level6.enabled = false
	$Level7.enabled = false
	$Level8.enabled = false
	$Level9.enabled = false
	$Level10.enabled = false
	$Level11.enabled = false
	$Level12.enabled = false
	array_of_levels.append($Level1)
	array_of_levels.append($Level2)
	array_of_levels.append($Level3)
	array_of_levels.append($Level4)
	array_of_levels.append($Level5)
	array_of_levels.append($Level6)
	array_of_levels.append($Level7)
	array_of_levels.append($Level8)
	array_of_levels.append($Level9)
	array_of_levels.append($Level10)
	array_of_levels.append($Level11)
	array_of_levels.append($Level12)


## Returns the "Start Point" position in the current tilemap layer.
func _find_start_point() -> Vector2i:
	var used_cells
	if array_of_levels[current_level].get_used_cells_by_id(4, Vector2i.ZERO, 1) != []:
		used_cells = array_of_levels[current_level].get_used_cells_by_id(4, Vector2i.ZERO, 1)

	elif array_of_levels[current_level].get_used_cells_by_id(4, Vector2i.ZERO, 2) != []:
		used_cells = array_of_levels[current_level].get_used_cells_by_id(4, Vector2i.ZERO, 2)
	
	elif array_of_levels[current_level].get_used_cells_by_id(4, Vector2i.ZERO, 3) != []:
		used_cells = array_of_levels[current_level].get_used_cells_by_id(4, Vector2i.ZERO, 3)
	
	elif array_of_levels[current_level].get_used_cells_by_id(4, Vector2i.ZERO, 4) != []:
		used_cells = array_of_levels[current_level].get_used_cells_by_id(4, Vector2i.ZERO, 4)

	# Level 1 Stage 1
	else:
		used_cells = array_of_levels[current_level].get_used_cells_by_id(9, Vector2i.ZERO, 1)

	var world_position = array_of_levels[current_level].to_global(array_of_levels[current_level].map_to_local(used_cells[0]))
	world_position -= Vector2(8, 28)
	return world_position


## Reset [current_level] to 0 without resetting the level array.
## [br] Used with the player taking damage.
func _reset_local_levels():
	array_of_levels[current_level].enabled = false
	current_level = 0
	array_of_levels[current_level].enabled = true
	player.position = _find_start_point()


## Adds 1 to the [current_level].
## [br] Used with the player beating a level.
func _add_local_level():
	array_of_levels[current_level].enabled = false
	current_level += 1
	array_of_levels[current_level].enabled = true
	player.position = _find_start_point()


## Disables the player's movement, player's animation tree, and scene timer.
func _stop_scene():
	if array_of_levels:
		array_of_levels[current_level].get_node("Music").stop()
	player.reset_momentum()
	GlobalScene.movement_enabled = false
	player_tree.active = false
	timer.stop()


## Enables the player's movement, player's animation tree, and scene timer.
func _start_scene():
	var music_player = array_of_levels[current_level].get_node_or_null("Music") as AudioStreamPlayer
	
	if music_player and music_player.stream:
		var song_length = music_player.stream.get_length()
		var target_pitch = song_length / level_speed
		music_player.pitch_scale = target_pitch
		music_player.play()

	array_of_levels[current_level].get_node("Music").play()
	timer.start(level_speed)
	player_tree.active = true
	GlobalScene.movement_enabled = true


## Awaits [Timer] signal for a timeout.
func _on_timer_timeout() -> void:
	_stop_scene()

	var player_hp_left = player_hp_container.get_child_count()
	if player_hp_left == 1:
		await _transition_out()
		await _player_game_over()
	else:
		await _transition_out()
		await _player_hit()
		_reset_local_levels()
		await _player_hit_transition_in()
		timer.start(level_speed)

		_start_scene()


## When the player enters a portal.
## [br] Used in [end_point.gd].
func portal_entered() -> void:
	_stop_scene()

	await _transition_out()
	_add_local_level()
	await _transition_in()

	_start_scene()


## When the player enters the enemy.
func _on_enemy_enter() -> void:
	_stop_scene()

	if enemy_hp_container.get_child_count() == 1:
		await _transition_out()
		await _enemy_kill()
		await _revive_animation()
		## Just to stop breaking between stages
		await _health_set_up(true)
	else:
		await _transition_out()
		await _enemy_hit()

	array_of_levels[current_level].enabled = false
	array_of_levels.pop_front()
	array_of_levels.pop_front()
	array_of_levels.pop_front()
	array_of_levels.pop_front()
	current_level = 0

	if level_speed == 5.5:
		level_speed = 5.0
		player.speed_factor = 5.5
	else:
		level_speed = 5.5
		player.speed_factor = 5.0

	array_of_levels[current_level].enabled = true
	player.position = _find_start_point()

	await _enemy_hit_transition_in()

	_start_scene()

#region -- Battle Animations --
func _battle_start():
	state_machine.travel("BattleStart")
	await anim_tree.animation_finished

func _battle_revive():
	state_machine.travel("BattleRevive")
	await anim_tree.animation_finished

func _battle_intro():
	state_machine.travel("BattleIntro")
	await anim_tree.animation_finished

func _battle_transition_in():
	state_machine.travel("BattleTransitionIn")
	await anim_tree.animation_finished
#endregion

#region -- Player Animations --
func _player_hit():
	state_machine.travel("PlayerHit")
	await anim_tree.animation_finished

func _player_hit_transition_in():
	state_machine.travel("PlayerHitTransitionIn")
	await anim_tree.animation_finished

func _player_game_over():
	state_machine.travel("GameOver")
	await anim_tree.animation_finished

func _revive_animation():
	state_machine.travel("PlayerRevive")
	await anim_tree.animation_finished
#endregion

#region -- Enemy Animations --
func _enemy_hit():
	state_machine.travel("EnemyHit")
	await anim_tree.animation_finished

func _enemy_hit_transition_in():
	state_machine.travel("EnemyHitTransitionIn")
	await anim_tree.animation_finished

func _enemy_kill():
	state_machine.travel("EnemyDeath")
	await anim_tree.animation_finished
#endregion

#region -- Transition Animations --
func _transition_in():
	state_machine.travel("LevelWin")
	await anim_tree.animation_finished
	state_machine.travel("TransitionIn")
	await anim_tree.animation_finished

func _transition_out():
	state_machine.travel("TransitionOut")
	await anim_tree.animation_finished
#endregion
