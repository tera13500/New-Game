extends CanvasLayer
class_name EventPopup

signal option_chosen(effect: Dictionary, event_data: EventData)

var _current_event: EventData

func _ready() -> void:
	hide_popup()

func show_event(event_data: EventData) -> void:
	_current_event = event_data
	%PopupTitle.text = event_data.title
	%PopupDesc.text = event_data.description
	%Severity.text = _severity_label(event_data)
	%Severity.modulate = _severity_color(event_data)
	var target_text: String = "대상 전체" if event_data.target_elevator_id < 0 else "대상 %d호기" % event_data.target_elevator_id
	var pretty_tags: Array[String] = []
	for cid: String in event_data.component_tags:
		var info: Array = GameState.COMPONENT_CATALOG.get(cid, [cid])
		pretty_tags.append(str(info[0]))
	var chip_text: String = "장치 없음" if pretty_tags.is_empty() else " · ".join(pretty_tags.slice(0, 3))
	%Tags.text = "%s  |  %s" % [target_text, chip_text]
	%Recommend.text = "권장 액션: %s" % (event_data.recommended_action if event_data.recommended_action != "" else "상황 판단")
	for child: Node in %OptionList.get_children():
		child.queue_free()
	for option: Dictionary in event_data.options:
		var button: Button = Button.new()
		button.text = "%s\n%s" % [str(option.get("label", "선택")), _effect_hint(option.get("effect", {}))]
		button.custom_minimum_size = Vector2(0, 56)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(func() -> void:
			var payload: Dictionary = option.get("effect", {}).duplicate()
			if option.has("upgrade_id"):
				payload["upgrade_id"] = option["upgrade_id"]
			if option.has("fault_action"):
				payload["fault_action"] = option["fault_action"]
			emit_signal("option_chosen", payload, _current_event)
			hide_popup()
		)
		%OptionList.add_child(button)
	visible = true
	%Panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(%Panel, "modulate:a", 1.0, 0.14)
	tween.parallel().tween_property(%Panel, "position:y", %Panel.position.y + 8.0, 0.001)
	tween.tween_property(%Panel, "position:y", %Panel.position.y, 0.14)

func hide_popup() -> void:
	visible = false

func _severity_label(event_data: EventData) -> String:
	if event_data.event_level == "major":
		return "[중요] 즉시 판단 필요"
	if event_data.severity in ["warning", "risk", "fault"]:
		return "[경고] 모니터링 필요"
	return "[정보] 자동 처리 가능"

func _severity_color(event_data: EventData) -> Color:
	if event_data.event_level == "major":
		return Color("#f2b84b")
	if event_data.severity in ["warning", "risk", "fault"]:
		return Color("#e66b6b")
	return Color("#66bfff")

func _effect_hint(effect: Dictionary) -> String:
	var parts: Array[String] = []
	if effect.has("money"):
		parts.append("예산 %s" % int(effect["money"]))
	if effect.has("safety"):
		parts.append("안전 %+0.1f" % float(effect["safety"]))
	if effect.has("satisfaction"):
		parts.append("만족 %+0.1f" % float(effect["satisfaction"]))
	if effect.has("complaints"):
		parts.append("민원 %+d" % int(effect["complaints"]))
	if parts.is_empty():
		return "영향: 상태 변화"
	return "영향: " + ", ".join(parts)
