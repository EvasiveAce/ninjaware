extends Node2D


const dummy_stage = preload("res://Stages/DummyStage/Scenes/dummy_stage.tscn")

func _ready() -> void:
    $OpeningScene/AnimationTree.active = true    

    $OpeningScene/AnimationTree.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(_anim_name: String) -> void:
        var stage = dummy_stage.instantiate()
        add_child(stage)
        $OpeningScene.queue_free()