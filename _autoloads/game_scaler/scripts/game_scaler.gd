extends SubViewportContainer
## Root of the game: set game_scaler.tscn as the main scene and attach this script
## to its root node. Owns the cutscene -> stage sequence.
##
## [br] [GameViewport] holds exactly one "screen" at a time (a cutscene or a stage).
## [br] [CanvasLayer/TransitionUI] is shared by every stage, so it is reset between stages.

const OPENING_CUTSCENE := preload("res://ui/cutscenes/opening_cutscene/scenes/opening_cutscene.tscn")
const POTATOMOUS_CUTSCENE := preload("res://ui/cutscenes/potatomous_cutscene/scenes/potatomous_cutscene.tscn")
const DUMMY_STAGE := preload("res://entities/stages/dummy_stage/scenes/dummy_stage.tscn")
const POTATOMOUS_STAGE := preload("res://entities/stages/potatomous_stage/scenes/potatomous_stage.tscn")


## The whole game, in order. Adding a stage = adding one entry here.
## [br] cutscene_state: AnimationTree state/animation that is the cutscene's main scene.
## [br] start_on_press: cutscene sits on its title state until ui_accept is pressed.
## [br] skippable: ui_accept during the main animation skips straight to the stage.
const SEQUENCE := [
	{
		"cutscene": OPENING_CUTSCENE,
		"cutscene_state": &"Opening",
		"start_on_press": true,
		"skippable": true,
		"stage": DUMMY_STAGE,
	},
	{
		"cutscene": POTATOMOUS_CUTSCENE,
		"cutscene_state": &"PotatomousCutscene",
		"start_on_press": false,
		"skippable": false,
		"stage": POTATOMOUS_STAGE,
	},
]
 
@onready var _viewport: SubViewport = $GameViewport
@onready var _transition_ui: Node = $CanvasLayer/TransitionUI

var _step := -1
var _entry: Dictionary
## Whatever is currently inside the viewport (cutscene or stage).
var _screen: Node
## Only set while a cutscene is on screen. null during gameplay.
var _cutscene_tree: AnimationTree
var _cutscene_playback: AnimationNodeStateMachinePlayback
var _cutscene_started := false
var _busy := false


func _ready() -> void:
	_next_step()


func _input(event: InputEvent) -> void:
	# Only react while a cutscene is on screen: ui_accept is also the jump button.
	if _cutscene_tree == null or _busy or not event.is_action_pressed("ui_accept"):
		return
 
	if not _cutscene_started:
		_cutscene_started = true
		_cutscene_playback.travel("TransitionIn")
	elif _entry["skippable"] and _cutscene_playback.get_current_node() == _entry["cutscene_state"]:
		_finish_cutscene()

## Moves to the next entry in [SEQUENCE], or ends the demo.
func _next_step() -> void:
	_step += 1
	if _step >= SEQUENCE.size():
		_end_of_demo()
		return
 
	_entry = SEQUENCE[_step]
	_play_cutscene(_entry["cutscene"])

#region -- Cutscenes --
func _play_cutscene(scene: PackedScene) -> void:
	_set_screen(scene.instantiate())
 
	_cutscene_tree = _screen.get_node("AnimationTree")
	_cutscene_playback = _cutscene_tree.get("parameters/playback")
	_cutscene_started = not _entry["start_on_press"]
	_cutscene_tree.animation_finished.connect(_on_cutscene_animation_finished)
	_cutscene_tree.active = true

func _on_cutscene_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"TransitionIn":
		_cutscene_playback.travel(_entry["cutscene_state"])
	elif anim_name == _entry["cutscene_state"]:
		_finish_cutscene()

## Plays the cutscene's TransitionOut, then starts the stage that belongs to it.
func _finish_cutscene() -> void:
	if _busy:
		return
	_busy = true
 
	_cutscene_playback.travel("TransitionOut")
 
	# Wait for TransitionOut specifically, so another animation ending
	# at the same moment (e.g. the main cutscene) can't trigger this early.
	var finished: StringName = &""
	while finished != &"TransitionOut":
		finished = await _cutscene_tree.animation_finished
 
	_cutscene_tree = null
	_start_stage(_entry["stage"])
	_busy = false
#endregion

#region -- Stages --
func _start_stage(scene: PackedScene) -> void:
	# The TransitionUI outlives stages, so wipe leftovers BEFORE the new stage's _ready runs.
	_transition_ui.reset_for_new_stage()
 
	_set_screen(scene.instantiate())
	_screen.stage_cleared.connect(_on_stage_cleared, CONNECT_ONE_SHOT)
 
 
func _on_stage_cleared() -> void:
	_next_step()
#endregion

## Swaps the current screen. The old one leaves the tree immediately, so
## get_first_node_in_group("Stage") never sees two stages at once.
func _set_screen(new_screen: Node) -> void:
	if _screen:
		_viewport.remove_child(_screen)
		_screen.queue_free()
 
	_screen = new_screen
	_viewport.add_child(_screen)
 
 
func _end_of_demo() -> void:
	# TODO: replace with a real "Thanks for playing" screen.
	# For now, go back to the title.
	get_tree().reload_current_scene()
