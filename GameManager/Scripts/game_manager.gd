extends Node2D


const DummyStage = preload("res://DummyStage/Scenes/DummyStage.tscn")

func _ready() -> void:
    $OpeningScene/AnimationTree.active = true    

    $OpeningScene/AnimationTree.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(_anim_name: String) -> void:
        var stage = DummyStage.instantiate()
        add_child(stage)
        $OpeningScene.queue_free()