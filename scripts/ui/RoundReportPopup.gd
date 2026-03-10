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
	%ReportTitle.text = "Day %d 운영 리포트" % int(summary.get("day", 0))
	%Metrics.text = "평균 대기 %.1f | 고장 %d | 점검 지연 %d" % [
		float(summary.get("avg_waiting", 0.0)),
		int(summary.get("fault_count", 0)),
		int(summary.get("inspection_overdue", 0))
	]
	var goal_result: Dictionary = summary.get("goal_result", {"success": false, "reward": 0})
	var goal_line: String = "목표: %s / %s" % [
		summary.get("goal_text", "-"),
		"성공 +%d원" % int(goal_result.get("reward", 0)) if bool(goal_result.get("success", false)) else "미달성"
	]
	var milestones: Array = summary.get("milestones", [])
	var milestone_text: String = "없음" if milestones.is_empty() else ", ".join(milestones)
	%Commentary.text = "%s\n- 예방 성과: %s\n- 취약 장치: %s\n- 놓친 신호: %s\n- 다음 권장: %s\n- 무고장 연속: %d일 (최고 %d일)\n- 마일스톤: %s (+%d원)" % [
		goal_line,
		summary.get("best_prevention", "-"),
		summary.get("critical_component", "-"),
		summary.get("missed_signal", "-"),
		summary.get("recommendation", "-"),
		int(summary.get("streak", 0)),
		int(summary.get("best_streak", 0)),
		milestone_text,
		int(summary.get("milestone_reward", 0))
	]
	%Footer.text = "예산 %s원 | 안전 %.1f | 만족 %.1f | 민원 %d\n%s" % [GameText.format_number(game_state.money), game_state.safety_score, game_state.satisfaction, game_state.complaints, str(summary.get("game_over_warning", "안정 운영 중"))]
	visible = true
	%Panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(%Panel, "modulate:a", 1.0, 0.16)
