extends BaseStage
## Second stage.
## [br] The main mechanic is the springing, potato bombs.
class_name PotatomousStage

func _init() -> void:
	anim_tree_scene = preload('res://entities/stages/potatomous_stage/scenes/potatomous_animation_tree.tscn')