extends CanvasLayer
class_name RoundReportPopup

signal continue_pressed

func _ready() -> void:
	%ContinueButton.pressed.connect(func() -> void:
		visible = false
		emit_signal("continue_pressed")
	)
	visible = false

func show_report(summary: Dictionary, game_state: GameState) -> void:
	%ReportTitle.text = "Day %d 리포트" % int(summary.get("day", 0))
	%Metrics.text = "평균 대기: %.1f\n고장 대수: %d\n점검 지연 대수: %d" % [
		float(summary.get("avg_waiting", 0.0)),
		int(summary.get("fault_count", 0)),
		int(summary.get("inspection_overdue", 0))
	]
	%Commentary.text = "%s\n\n현재 자산: %s원 | 안전 %.1f | 만족 %.1f | 민원 %d" % [
		str(summary.get("message", "")),
		_format_number(game_state.money),
		game_state.safety_score,
		game_state.satisfaction,
		game_state.complaints
	]
	visible = true

func _format_number(value: int) -> String:
	var text := str(value)
	var out := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
