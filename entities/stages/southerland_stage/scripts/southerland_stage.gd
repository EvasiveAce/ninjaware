extends BaseStage
## Third stage.
## [br] The main mechanic is projectile jumping.
class_name SoutherlandStage

func _init() -> void:
	anim_tree_scene = preload('res://entities/stages/dummy_stage/scenes/dummy_animation_tree.tscn')