extends Node2D


const dummy_stage = preload("res://entities/stages/dummy_stage/scenes/dummy_stage.tscn")
const potatomous_stage = preload("res://entities/stages/potatomous_stage/scenes/potatomous_stage.tscn")
var is_loading := false
var playback 
var current_node
var anim_tree

func _ready() -> void:
	playback = $OpeningCutscene/AnimationTree.get("parameters/playback")
	$OpeningCutscene/AnimationTree.active = true
	$OpeningCutscene/AnimationTree.animation_finished.connect(_on_animation_finished)

func _input(event: InputEvent) -> void:
	current_node = playback.get_current_node()
	if event.is_action_pressed("ui_accept") and current_node == "Opening":
		_start_game()
	elif event.is_action_pressed("ui_accept") and current_node != "Opening" and !is_loading:
		playback.travel("TransitionIn")


func _start_game():
	if is_loading:
		return

	is_loading = true

	playback.travel("TransitionOut")
	await $OpeningCutscene/AnimationTree.animation_finished

	var stage = dummy_stage.instantiate()
	add_child(stage)

	for child in stage.get_node('TransitionUI').get_children():
		if child.name.contains("AnimationTree"):
			anim_tree = child
			break 

	anim_tree.animation_finished.connect(_on_dummy_stage_finished)
	$OpeningCutscene.queue_free()


func _on_animation_finished(_anim_name: String) -> void:
	if _anim_name == "TransitionIn":
		playback.travel("Opening")
	elif _anim_name == "Opening":
		_start_game()

func _on_dummy_stage_finished(_anim_name: String) -> void:
	if _anim_name.contains("09EnemyDeath"):
		var stage2 = potatomous_stage.instantiate()
		add_child(stage2)

		for child in stage2.get_node('TransitionUI').get_children():
			if child.name.contains("AnimationTree"):
				anim_tree = child
				break 

		anim_tree.animation_finished.connect(_on_potatomous_stage_finished)
		$DummyStage.queue_free()


func _on_potatomous_stage_finished(_anim_name: String) -> void:
	if _anim_name.contains("09EnemyDeath"):
		var stage = dummy_stage.instantiate()
		add_child(stage)

		for child in stage.get_node('TransitionUI').get_children():
			if child.name.contains("AnimationTree"):
				anim_tree = child
				break 

		anim_tree.animation_finished.connect(_on_dummy_stage_finished)
		$PotatomousStage.queue_free()
