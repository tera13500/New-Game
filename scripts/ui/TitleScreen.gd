extends Control

@onready var version_label: Label = %VersionLabel
@onready var helper_label: Label = %HelperLabel

func _ready() -> void:
	AppState.try_apply_pixel_font(get_theme())
	version_label.text = "v%s" % GameState.GAME_VERSION
	helper_label.text = "처음 플레이라면 튜토리얼 시작을 권장합니다." if AppState.first_run else "모드를 선택해 운영을 시작하세요."

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
