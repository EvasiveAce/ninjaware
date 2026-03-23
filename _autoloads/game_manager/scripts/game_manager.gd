extends Node2D


const dummy_stage = preload("res://entities/stages/dummy_stage/scenes/dummy_stage.tscn")
const potatomous_cutscene = preload("res://ui/cutscenes/potatomous_cutscene/scenes/potatomous_cutscene.tscn")
const potatomous_stage = preload("res://entities/stages/potatomous_stage/scenes/potatomous_stage.tscn")
var is_loading := false
var playback 
var current_node
var anim_tree
var current_stage_to_use
var current_animation_tree

func _ready() -> void:
	current_animation_tree = $OpeningCutscene/AnimationTree
	playback = current_animation_tree.get("parameters/playback")
	current_animation_tree.active = true
	current_animation_tree.animation_finished.connect(_on_animation_finished)

func _input(event: InputEvent) -> void:
	current_node = playback.get_current_node()
	if event.is_action_pressed("ui_accept") and current_node == "Opening":
		_start_game(dummy_stage)
	elif event.is_action_pressed("ui_accept") and current_node != "Opening" and !is_loading:
		playback.travel("TransitionIn")


func _start_game(stage_to_use):
	if is_loading:
		return

	is_loading = true

	playback.travel("TransitionOut")
	await current_animation_tree.animation_finished

	current_stage_to_use = stage_to_use
	var stage = current_stage_to_use.instantiate()
	print(stage)
	add_child(stage)

	for child in stage.get_node('TransitionUI').get_children():
		if child.name.contains("AnimationTree"):
			anim_tree = child
			break 

	anim_tree.animation_finished.connect(_on_enemy_stage_finished)
	if $OpeningCutscene:
		$OpeningCutscene.queue_free()
	elif $PotatomousCutscene:
		$PotatomousCutscene.queue_free()
	is_loading = false

func _on_animation_finished(_anim_name: String) -> void:
	if _anim_name == "TransitionIn":
		playback.travel("Opening")
	elif _anim_name == "Opening":
		_start_game(dummy_stage)

func _on_enemy_stage_finished(_anim_name: String) -> void:
	if get_tree().get_first_node_in_group("Stage").name == 'DummyStage':
		if _anim_name.contains("09EnemyDeath"):
			var cutsceneToAdd = potatomous_cutscene.instantiate()
			add_child(cutsceneToAdd)
			current_animation_tree = cutsceneToAdd.get_node('AnimationTree')
			playback = current_animation_tree.get("parameters/playback")
			cutsceneToAdd.get_node('AnimationTree').active = true
			cutsceneToAdd.get_node('AnimationTree').animation_finished.connect(_on_potatomous_animation_finished)

			# var stage = potatomous_stage.instantiate()
			# add_child(stage)

			# for child in stage.get_node('TransitionUI').get_children():
			# 	if child.name.contains("AnimationTree"):
			# 		anim_tree = child
			# 		break 

			#anim_tree.animation_finished.connect(_on_potatomous_stage_finished)
			$DummyStage.queue_free()


func _on_potatomous_animation_finished(_anim_name: String) -> void:
	if _anim_name == "TransitionIn":
		playback.travel("PotatomousCutscene")
	elif _anim_name == "PotatomousCutscene":
		print('her?')
		_start_game(potatomous_stage)

# func _on_potatomous_stage_finished(_anim_name: String) -> void:
# 	if _anim_name.contains("09EnemyDeath"):
# 		var stage = dummy_stage.instantiate()
# 		add_child(stage)

# 		for child in stage.get_node('TransitionUI').get_children():
# 			if child.name.contains("AnimationTree"):
# 				anim_tree = child
# 				break 

# 		anim_tree.animation_finished.connect(_on_dummy_stage_finished)
# 		$PotatomousStage.queue_free()
