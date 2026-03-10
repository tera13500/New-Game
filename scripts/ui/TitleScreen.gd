extends Control

@onready var version_label: Label = %VersionLabel
@onready var helper_label: Label = %HelperLabel

func _ready() -> void:
	version_label.text = "v%s" % GameState.GAME_VERSION
	if AppState.first_run:
		helper_label.text = "처음이라면 '튜토리얼 시작'을 권장합니다."
	else:
		helper_label.text = "원하는 시작 모드를 선택하세요."

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
