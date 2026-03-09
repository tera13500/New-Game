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
	%Severity.text = "심각도: %s" % event_data.severity
	var target_text: String = "전체 시스템" if event_data.target_elevator_id < 0 else "대상 호기: %d호기" % event_data.target_elevator_id
	var pretty_tags: Array[String] = []
	for cid: String in event_data.component_tags:
		var info: Array = GameState.COMPONENT_CATALOG.get(cid, [cid])
		pretty_tags.append(str(info[0]))
	%Tags.text = "%s | 관련 장치: %s" % [target_text, ("없음" if pretty_tags.is_empty() else ", ".join(pretty_tags))]
	%Recommend.text = "권장 액션: %s" % (event_data.recommended_action if event_data.recommended_action != "" else "상황 판단")
	for child: Node in %OptionList.get_children():
		child.queue_free()
	for option: Dictionary in event_data.options:
		var button: Button = Button.new()
		button.text = str(option.get("label", "선택"))
		button.custom_minimum_size = Vector2(0, 38)
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
