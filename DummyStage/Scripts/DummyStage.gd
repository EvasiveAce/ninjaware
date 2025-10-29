extends Node2D

@export var defaultHP := 3
@export var hpEntity : PackedScene

@export var enemyHP := 3
@export var enemyHPEntity : PackedScene

var currentLevel := 0
var currentEnemy := 0

var arrayOfPositions := [
		Vector2(264.0, 700.0), Vector2(88.0, 700.0), Vector2(88.0, 252.0), Vector2(88.0, 444.0), 
		Vector2(88.0, 444.0), Vector2(88.0, 188.0), Vector2(88.0, 508.0), Vector2(88.0, 700.0),
		Vector2(88.0, 828.0), Vector2(88.0, 764.0), Vector2(88.0, 316.0), Vector2(88.0, 448.0)
	]

var arrayOfPortals := [
		Vector2(1830.0, 692.0), Vector2(1830.0, 244.0), Vector2(1830.0, 436.0), Vector2(2036.0, 436.0), 
		Vector2(1830.0, 180.0), Vector2(1830.0, 500.0), Vector2(1830.0, 692.0), Vector2(2036.0, 436.0),
		Vector2(1830.0, 756.0), Vector2(1830.0, 308.0), Vector2(1830.0, 308.0), Vector2(2036.0, 436.0)
	]

var arrayOfLevels : Array[Node]

var arrayOfEnemys := [Vector2(1720.0, 432.0), Vector2(1720.0, 816.0), Vector2(1736.0, 752.0)]

var speed := 6.0

var arrayOfPositionsToUse = []
var arrayOfPortalsToUse = []
var arrayOfEnemysToUse = []

var anim_tree
var state_machine

func _ready() -> void:
	GlobalScene.enabledMovement = false
	# Get the AnimationTree
	anim_tree = $TransitionIntro/AnimationTree
	state_machine = anim_tree.get("parameters/playback")
	await _health_set_up()


func _health_set_up():
	_arrays_reset()
	for hp in defaultHP:
		await get_tree().create_timer(0.1).timeout
		$TransitionIntro/TransitionSprite/HPContainer.add_child(hpEntity.instantiate())
		$TransitionIntro/LivesAdded.play()

	await _battle_start()
	
	for hp in enemyHP:
		await get_tree().create_timer(0.1).timeout
		$TransitionIntro/TransitionSprite/EnemyHPContainer.add_child(enemyHPEntity.instantiate())
		$TransitionIntro/LivesEnemyAdded.play()

	
	$Player.position = arrayOfPositionsToUse[currentLevel]
	$EndPoint.position = arrayOfPortalsToUse[currentLevel]
	arrayOfLevels[currentLevel].enabled = true

	await _battle_intro()
	$Timer.start(speed)
	$ProgressBar.max_value = $Timer.wait_time
	await _battle_transition_in()
	GlobalScene.enabledMovement = true

func _arrays_reset():
	arrayOfLevels = []
	currentLevel = 0
	currentEnemy = 0
	$Stage1.enabled = false
	$Stage2.enabled = false
	$Stage3.enabled = false
	$Stage4.enabled = false
	$Stage5.enabled = false
	$Stage6.enabled = false
	$Stage7.enabled = false
	$Stage8.enabled = false
	$Stage9.enabled = false
	$Stage10.enabled = false
	$Stage11.enabled = false
	$Stage12.enabled = false
	arrayOfLevels.append($Stage1)
	arrayOfLevels.append($Stage2)
	arrayOfLevels.append($Stage3)
	arrayOfLevels.append($Stage4)
	arrayOfLevels.append($Stage5)
	arrayOfLevels.append($Stage6)
	arrayOfLevels.append($Stage7)
	arrayOfLevels.append($Stage8)
	arrayOfLevels.append($Stage9)
	arrayOfLevels.append($Stage10)
	arrayOfLevels.append($Stage11)
	arrayOfLevels.append($Stage12)

	arrayOfPositionsToUse = []
	arrayOfPositionsToUse = arrayOfPositions.duplicate(true)

	arrayOfPortalsToUse = []
	arrayOfPortalsToUse = arrayOfPortals.duplicate(true)

	arrayOfEnemysToUse = []
	arrayOfEnemysToUse = arrayOfEnemys.duplicate(true)

func _revive_set_up():
	_arrays_reset()
	for hp in defaultHP:
		await get_tree().create_timer(0.1).timeout
		$TransitionIntro/TransitionSprite/HPContainer.add_child(hpEntity.instantiate())
		$TransitionIntro/LivesAdded.play()

	await _battle_revive()
	var hpDifference = $TransitionIntro/TransitionSprite/EnemyHPContainer.get_child_count()

	for hp in (enemyHP - hpDifference):
		await get_tree().create_timer(0.1).timeout
		$TransitionIntro/TransitionSprite/EnemyHPContainer.add_child(enemyHPEntity.instantiate())
		$TransitionIntro/LivesEnemyAdded.play()
	
	$Player.position = arrayOfPositionsToUse[currentLevel]
	$EndPoint.position = arrayOfPortalsToUse[currentLevel]
	arrayOfLevels[currentLevel].enabled = true

	await _battle_intro()
	$Timer.start(speed)
	$ProgressBar.max_value = $Timer.wait_time
	await _battle_transition_in()
	GlobalScene.enabledMovement = true


func _on_timer_timeout() -> void:
	GlobalScene.enabledMovement = false

	$Dummy.visible = false
	$Dummy/Area2D/CollisionShape2D.disabled = true

	var hpLeft = $TransitionIntro/TransitionSprite/HPContainer.get_child_count()
	if  hpLeft > 0:
		if hpLeft == 1:
			await _transition_out()
			await _player_game_over()
		else:
			await _transition_out()
			if hpLeft == 3:
				await _player_hit_ouch()
				arrayOfLevels[currentLevel].enabled = false
				currentLevel = 0
				$Player.position = arrayOfPositionsToUse[currentLevel]
				$EndPoint.position = arrayOfPortalsToUse[currentLevel]
				arrayOfLevels[currentLevel].enabled = true
				await _ouch_transition_in()
			elif hpLeft == 2:
				await _player_hit_augh()
				arrayOfLevels[currentLevel].enabled = false
				currentLevel = 0
				$Player.position = arrayOfPositionsToUse[currentLevel]
				$EndPoint.position = arrayOfPortalsToUse[currentLevel]
				arrayOfLevels[currentLevel].enabled = true
				await _augh_transition_in()
			$Timer.start(speed)
			GlobalScene.enabledMovement = true

func _process(_delta: float) -> void:
	var current_state = state_machine.get_current_node()
	if current_state == "InsertCoin":
		if Input.is_action_just_pressed('ui_accept'):
			await _revive_animation()
			await _revive_set_up()

	$ProgressBar.value = $Timer.time_left
	if $Player.position.y >= 950:
		$Player.position.y = -1000
		$Timer.stop()
		_on_timer_timeout()


## -=Battle Animations=- ##
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
## -=End Battle Animations=- ##


## -=Player Animations=- ##
func _player_hit_ouch():
	state_machine.travel("PlayerHitOuch")
	await anim_tree.animation_finished

func _player_hit_augh():
	state_machine.travel("PlayerHitAugh")
	await anim_tree.animation_finished

func _ouch_transition_in():
	state_machine.travel("OuchTransitionIn")
	await anim_tree.animation_finished

func _augh_transition_in():
	state_machine.travel("AughTransitionIn")
	await anim_tree.animation_finished

func _player_game_over():
	state_machine.travel("GameOver")
	await anim_tree.animation_finished

func _revive_animation():
	state_machine.travel("ReviveLevel")
	await anim_tree.animation_finished
## -=End Player Animations=- ##


## -=Enemy Animations=- ##
func _enemy_hit_first():
	state_machine.travel("DummyHitFirst")
	await anim_tree.animation_finished

func _enemy_first_transition_in():
	state_machine.travel("DummyHitFirstTransitionIn")
	await anim_tree.animation_finished

func _enemy_hit_second():
	state_machine.travel("DummyHitSecond")
	await anim_tree.animation_finished

func _enemy_second_transition_in():
	state_machine.travel("DummyHitSecondTransitionIn")
	await anim_tree.animation_finished

func _enemy_kill():
	state_machine.travel("DummyDeath")
	await anim_tree.animation_finished
## -=End Enemy Animations=- ##


func _transition_in():
	state_machine.travel("TransitionIn")
	await anim_tree.animation_finished

func _transition_out():
	state_machine.travel("TransitionOut")
	await anim_tree.animation_finished


# Portal Enter
func _on_area_2d_body_entered(_body: Node2D) -> void:
	GlobalScene.enabledMovement = false
	$Player/AnimationTree.active = false
	$Timer.stop()
	await _transition_out()
	arrayOfLevels[currentLevel].enabled = false
	currentLevel += 1
	$Player.position = arrayOfPositionsToUse[currentLevel]
	$EndPoint.position = arrayOfPortalsToUse[currentLevel]
	if currentLevel == 3:
		currentEnemy += 1
		if currentEnemy == 3:
			$Dummy.flip_h = true
		else:
			$Dummy.flip_h = false
		$Dummy.visible = true
		$Dummy/Area2D/CollisionShape2D.disabled = false
		$Dummy.position = arrayOfEnemysToUse[0]
	arrayOfLevels[currentLevel].enabled = true
	await _transition_in()
	$Timer.start(speed)
	GlobalScene.enabledMovement = true
	$Player/AnimationTree.active = true

func _on_area_2d_body_entered_dummy(_body: Node2D) -> void:
	if GlobalScene.enabledMovement:
		GlobalScene.enabledMovement = false
		$Player/AnimationTree.active = false
		$Timer.stop()
		$TransitionIntro/TransitionSprite/VersusLabel.text = "VERSUS"
		if $TransitionIntro/TransitionSprite/EnemyHPContainer.get_child_count() == 1:
			await _transition_out()
			await _enemy_kill()
		elif $TransitionIntro/TransitionSprite/EnemyHPContainer.get_child_count() == 2:
			await _transition_out()
			await _enemy_hit_second()
		else:
			await _transition_out()
			await _enemy_hit_first()
		arrayOfLevels[currentLevel].enabled = false

		arrayOfLevels.pop_front()
		arrayOfLevels.pop_front()
		arrayOfLevels.pop_front()
		arrayOfLevels.pop_front()

		arrayOfPositionsToUse.pop_front()
		arrayOfPositionsToUse.pop_front()
		arrayOfPositionsToUse.pop_front()
		arrayOfPositionsToUse.pop_front()

		arrayOfPortalsToUse.pop_front()
		arrayOfPortalsToUse.pop_front()
		arrayOfPortalsToUse.pop_front()
		arrayOfPortalsToUse.pop_front()
		arrayOfEnemysToUse.pop_front()


		currentLevel = 0
		if speed == 5.0:
			speed = 4.0
			$Player.speedFactor = 5.5
		else:
			speed = 5.0
			$Player.speedFactor = 5.0

		$Dummy.visible = false
		$Dummy/Area2D/CollisionShape2D.disabled = true
		$Dummy.position = arrayOfEnemysToUse[0]
		arrayOfLevels[currentLevel].enabled = true

		$Player.position = arrayOfPositionsToUse[currentLevel]
		$EndPoint.position = arrayOfPortalsToUse[currentLevel]

		if $TransitionIntro/TransitionSprite/EnemyHPContainer.get_child_count() == 2:
			await _enemy_first_transition_in()
		else:
			await _enemy_second_transition_in()
		
		$Timer.start(speed)
		GlobalScene.enabledMovement = true
		$Player/AnimationTree.active = true
