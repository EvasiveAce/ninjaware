extends BaseStage
## First stage.
## [br] The main mechanic is tutorial platforming.
class_name DummyStage

func _init() -> void:
	anim_tree_scene = preload('res://entities/stages/dummy_stage/scenes/dummy_animation_tree.tscn')