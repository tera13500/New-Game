extends Control

@onready var version_label: Label = %VersionLabel
@onready var helper_label: Label = %HelperLabel
@onready var decor_a: ColorRect = %ShaftDecorA
@onready var decor_b: ColorRect = %ShaftDecorB
@onready var decor_c: ColorRect = %ShaftDecorC

func _ready() -> void:
	AppState.try_apply_ui_font(get_theme())
	version_label.text = "v%s" % GameState.GAME_VERSION
	helper_label.text = "처음 플레이라면 튜토리얼 시작을 권장합니다." if AppState.first_run else "모드를 선택해 운영을 시작하세요."
	_animate_background()

func _animate_background() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(decor_a, "modulate:a", 0.42, 1.6)
	tween.parallel().tween_property(decor_b, "modulate:a", 0.35, 1.6)
	tween.parallel().tween_property(decor_c, "modulate:a", 0.4, 1.6)
	tween.tween_property(decor_a, "modulate:a", 0.24, 1.6)
	tween.parallel().tween_property(decor_b, "modulate:a", 0.2, 1.6)
	tween.parallel().tween_property(decor_c, "modulate:a", 0.24, 1.6)

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
