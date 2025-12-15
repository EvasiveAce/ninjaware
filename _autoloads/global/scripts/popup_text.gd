extends Node


func display_text(value: String, position: Vector2, font_size: int, outline_size: int):
	var text = Label.new()
	text.global_position = position
	text.text = value
	text.z_index = 1
	text.label_settings = LabelSettings.new()
	text.label_settings.font = preload('res://Wariowareinc-BWWdn.ttf')
	
	var color = "#FFF"
	
	text.label_settings.font_color = color
	text.label_settings.font_size = font_size
	text.label_settings.outline_color = "#000"
	text.label_settings.outline_size = outline_size
	
	call_deferred("add_child", text)
	
	await text.resized
	text.pivot_offset = Vector2(text.size / 2)
	
	var tween 
	
	tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		text, "position:y", text.position.y - 24, 0.15
	).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		text, "position:y", text.position.y, 0.3
	).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(
		text, "scale", Vector2.ZERO, 0.15
	).set_ease(Tween.EASE_IN).set_delay(0.5)

		
	await tween.finished
	text.queue_free()