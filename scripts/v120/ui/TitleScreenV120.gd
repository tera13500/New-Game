extends Control

func _ready() -> void:
	%VersionLabel.text = "v%s" % Terms.VERSION
	var loop: Tween = create_tween().set_loops()
	loop.tween_property(%BeamA, "modulate:a", 0.5, 1.8)
	loop.parallel().tween_property(%BeamB, "modulate:a", 0.34, 1.8)
	loop.tween_property(%BeamA, "modulate:a", 0.2, 1.8)
	loop.parallel().tween_property(%BeamB, "modulate:a", 0.16, 1.8)

func _on_tutorial_pressed() -> void:
	AppState.start_with_tutorial = true
	get_tree().change_scene_to_file("res://scenes/v120/GameScene.tscn")

func _on_quick_pressed() -> void:
	AppState.start_with_tutorial = false
	get_tree().change_scene_to_file("res://scenes/v120/GameScene.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
