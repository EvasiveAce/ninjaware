extends Node2D

@export var defaultHP := 1
@export var hpEntity : PackedScene

@export var enemyHP := 3
@export var enemyHPEntity : PackedScene

var currentLevel := 0
@export var arrayOfPositions : Array[Vector2]

@export var arrayOfPortals : Array[Vector2]

@export var arrayOfLevels : Array[Node]

@export var arrayOfEnemys : Array[Vector2]

@export var arrayOfPhrases : Array[String]

var speed := 5

var anim_tree
var state_machine

func _ready() -> void:
	# Get the AnimationTree
	anim_tree = $TransitionIntro/AnimationTree
	state_machine = anim_tree.get("parameters/playback")
	for hp in defaultHP:
		await get_tree().create_timer(0.1).timeout
		$TransitionIntro/TransitionSprite/HPContainer.add_child(hpEntity.instantiate())

	await _battle_start()
	
	for hp in enemyHP:
		await get_tree().create_timer(0.1).timeout
		$TransitionIntro/TransitionSprite/EnemyHPContainer.add_child(enemyHPEntity.instantiate())
	
	$Player.position = arrayOfPositions[currentLevel]
	$EndPoint.position = arrayOfPortals[currentLevel]
	arrayOfLevels[currentLevel].enabled = true

	await _transition_intro()
	$Timer.start(speed)
	$ProgressBar.max_value = $Timer.wait_time
	await _transition_in()

func _on_timer_timeout() -> void:
	GlobalScene.enabledMovement = false

	$Dummy.visible = false
	$Dummy/Area2D/CollisionShape2D.disabled = true

	var hpLeft = $TransitionIntro/TransitionSprite/HPContainer.get_child_count()
	if  hpLeft > 0:
		if hpLeft == 1:
			await _transition_out()
			await _game_over()
		else:
			if hpLeft == 3:
				$TransitionIntro/TransitionSprite/VersusLabel.text = "OUCH.."
			elif hpLeft == 2:
				$TransitionIntro/TransitionSprite/VersusLabel.text = "AAUGH!"
			await _transition_out()
			await _player_hit()
			arrayOfLevels[currentLevel].enabled = false
			currentLevel = 0
			$Player.position = arrayOfPositions[currentLevel]
			$EndPoint.position = arrayOfPortals[currentLevel]
			arrayOfLevels[currentLevel].enabled = true
			await _transition_in()
			$Timer.start(speed)
			GlobalScene.enabledMovement = true

func _process(delta: float) -> void:
	$ProgressBar.value = $Timer.time_left
	if $Player.position.y >= 950:
		$Player.position.y = -1000
		$Timer.stop()
		_on_timer_timeout()

func _transition_intro():
	state_machine.travel("Intro")
	await anim_tree.animation_finished

func _battle_start():
	state_machine.travel("BattleIn")
	await anim_tree.animation_finished

func _player_hit():
	state_machine.travel("PlayerHit")
	await anim_tree.animation_finished

func _game_over():
	state_machine.travel("GameOver")
	await anim_tree.animation_finished

func _transition_in():
	state_machine.travel("TransitionIn")
	await anim_tree.animation_finished

func _transition_out():
	state_machine.travel("TransitionOut")
	await anim_tree.animation_finished

func _on_area_2d_body_entered(body: Node2D) -> void:
	GlobalScene.enabledMovement = false
	$Player/AnimationTree.active = false
	$Timer.stop()
	$TransitionIntro/TransitionSprite/VersusLabel.text = arrayOfPhrases[currentLevel]
	await _transition_out()
	arrayOfLevels[currentLevel].enabled = false
	currentLevel += 1
	if currentLevel == 3:
		$Dummy.visible = true
		$Dummy/Area2D/CollisionShape2D.disabled = false
		$Dummy.position = arrayOfEnemys[0]
	arrayOfLevels[currentLevel].enabled = true
	$Player.position = arrayOfPositions[currentLevel]
	$EndPoint.position = arrayOfPortals[currentLevel]
	await _transition_in()
	$Timer.start(5)
	GlobalScene.enabledMovement = true
	$Player/AnimationTree.active = true


func _on_area_2d_body_entered_dummy(body: Node2D) -> void:
	pass # Replace with function body.
