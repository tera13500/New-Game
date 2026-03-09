extends Control

@onready var version_label: Label = %VersionLabel

func _ready() -> void:
	version_label.text = "v%s" % GameState.GAME_VERSION

func _on_start_tutorial_pressed() -> void:
	AppState.start_with_tutorial = true
	AppState.first_run = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_start_quick_pressed() -> void:
	AppState.start_with_tutorial = false
	AppState.first_run = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
