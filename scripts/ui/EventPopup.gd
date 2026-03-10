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
	var target_text: String = "전체" if event_data.target_elevator_id < 0 else "%d호기" % event_data.target_elevator_id
	var pretty_tags: Array[String] = []
	for cid: String in event_data.component_tags:
		var info: Array = GameState.COMPONENT_CATALOG.get(cid, [cid])
		pretty_tags.append(str(info[0]))
	%Tags.text = "대상: %s  |  장치: %s" % [target_text, ("없음" if pretty_tags.is_empty() else ", ".join(pretty_tags.slice(0, 3)))]
	%Recommend.text = "권장: %s" % (event_data.recommended_action if event_data.recommended_action != "" else "상황 판단")
	for child: Node in %OptionList.get_children():
		child.queue_free()
	for option: Dictionary in event_data.options:
		var button: Button = Button.new()
		button.text = str(option.get("label", "선택"))
		button.custom_minimum_size = Vector2(0, 40)
		button.clip_text = true
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
		return Color("#FFCE6B")
	if event_data.severity in ["warning", "risk", "fault"]:
		return Color("#FF9870")
	return Color("#85D7FF")
