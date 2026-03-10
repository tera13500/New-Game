extends Control

@onready var game_state: GameState = $GameState
@onready var event_manager: EventManager = $EventManager
@onready var round_manager: RoundManager = $RoundManager
@onready var unlock_manager: UnlockManager = $UnlockManager

@onready var building_view: BuildingView = %BuildingView
@onready var action_panel: ActionPanel = %ActionPanel
@onready var event_popup: EventPopup = %EventPopup
@onready var report_popup: RoundReportPopup = %RoundReportPopup
@onready var codex_popup: ComponentCodexPopup = %CodexPopup

@onready var tutorial_overlay: Control = %TutorialOverlay
@onready var tutorial_title: Label = %TutorialTitle
@onready var tutorial_step_label: Label = %TutorialStepLabel
@onready var tutorial_text: Label = %TutorialText
@onready var tutorial_next_button: Button = %TutorialNextButton
@onready var tutorial_hint: Label = %TutorialHint
@onready var tutorial_focus_frame: PanelContainer = %TutorialFocusFrame
@onready var dim_top: ColorRect = %DimTop
@onready var dim_left: ColorRect = %DimLeft
@onready var dim_right: ColorRect = %DimRight
@onready var dim_bottom: ColorRect = %DimBottom
@onready var recent_log_list: VBoxContainer = %RecentLogList

@onready var money_value: Label = %MoneyValue
@onready var safety_value: Label = %SafetyValue
@onready var satisfaction_value: Label = %SatisfactionValue
@onready var inspection_value: Label = %InspectionValue
@onready var complaint_value: Label = %ComplaintValue
@onready var time_value: Label = %TimeValue
@onready var version_label: Label = %VersionLabel

@onready var elevator_selector: OptionButton = %ElevatorSelector
@onready var status_badge: Label = %StatusBadge
@onready var work_summary: Label = %WorkSummary
@onready var floor_value: Label = %CurrentFloorValue
@onready var wear_value: Label = %WearValue
@onready var risk_value: Label = %RiskValue
@onready var inspection_day_value: Label = %InspectionDayValue
@onready var component_summary: Label = %ComponentSummary
@onready var campaign_summary: Label = %CampaignSummary
@onready var upgrades_value: Label = %UpgradesValue
@onready var recommend_label: Label = %RecommendLabel

var _selected_index: int = 0
var _selected_campaign_id: String = "door_safety"
var _event_cooldown_ticks: int = 0
var _major_event_count_day: int = 0
var _recent_logs: Array[Dictionary] = []
var _recent_event_ids: Array[String] = []
var _tutorial_step: int = 0
var _tutorial_waiting_action: String = ""
var _tutorial_pages: Array[Dictionary] = GameText.TUTORIAL_PAGES

func _ready() -> void:
	randomize()
	version_label.text = "v%s" % GameState.GAME_VERSION
	_connect_signals()
	_populate_selector()
	_add_recent_log("info", "운영 대시보드 준비 완료")
	_refresh_all()
	if AppState.start_with_tutorial:
		round_manager.stop()
		tutorial_overlay.visible = true
		_render_tutorial_step()
	else:
		tutorial_overlay.visible = false
		round_manager.start()

func _connect_signals() -> void:
	round_manager.tick_advanced.connect(_on_tick)
	round_manager.day_finished.connect(_on_day_finished)
	action_panel.action_requested.connect(_on_action_requested)
	action_panel.campaign_changed.connect(func(campaign_id: String) -> void: _selected_campaign_id = campaign_id)
	action_panel.codex_opened.connect(_open_codex)
	elevator_selector.item_selected.connect(_on_elevator_selected)
	event_popup.option_chosen.connect(_on_event_option_chosen)
	report_popup.continue_pressed.connect(func() -> void: round_manager.start())
	game_state.state_changed.connect(_refresh_all)
	unlock_manager.codex_unlocked.connect(_on_codex_unlocked)
	codex_popup.popup_closed.connect(func() -> void: round_manager.start())
	tutorial_next_button.pressed.connect(_on_tutorial_next)
	%TutorialSkipButton.pressed.connect(_on_tutorial_skip)

func _on_tick() -> void:
	if tutorial_overlay.visible:
		return
	game_state.advance_tick()
	if _event_cooldown_ticks > 0:
		_event_cooldown_ticks -= 1
		return
	var event_data: EventData = event_manager.get_event_for_state(game_state)
	if event_data == null:
		return
	if event_data.event_level == "major" and _can_show_major_popup(event_data):
		_major_event_count_day += 1
		_event_cooldown_ticks = GameBalance.EVENT_COOLDOWN_TICKS
		_recent_event_ids.push_front(event_data.event_id)
		if _recent_event_ids.size() > GameBalance.MAX_RECENT_EVENT_MEMORY:
			_recent_event_ids.resize(GameBalance.MAX_RECENT_EVENT_MEMORY)
		round_manager.stop()
		event_popup.show_event(event_data)
	else:
		_apply_minor_event(event_data)

func _can_show_major_popup(event_data: EventData) -> bool:
	if _major_event_count_day >= GameBalance.MAX_MAJOR_EVENTS_PER_DAY and event_data.event_id != "fault_real":
		return false
	if _recent_event_ids.has(event_data.event_id):
		return false
	return true

func _apply_minor_event(event_data: EventData) -> void:
	if event_data.options.size() > 0:
		var first_option: Dictionary = event_data.options[0]
		game_state.apply_effect(first_option.get("effect", {}), event_data.target_elevator_id)
	_add_recent_log("info" if event_data.severity == "normal" else "warn", "%s 자동 처리" % event_data.title)

func _on_day_finished() -> void:
	round_manager.stop()
	_major_event_count_day = 0
	_recent_event_ids.clear()
	unlock_manager.evaluate_titles(game_state)
	report_popup.show_report(game_state.finish_day(), game_state)

func _on_action_requested(action_id: String) -> void:
	if _tutorial_waiting_action != "" and action_id == _tutorial_waiting_action:
		_complete_tutorial_action_step()
	match action_id:
		"inspection":
			if _try_pay(action_id, "예산 부족: 정기점검 불가"):
				game_state.perform_regular_inspection(_selected_index)
				_add_recent_log("check", "정기점검 실행")
		"preventive":
			if _try_pay(action_id, "예산 부족: 예방정비 불가"):
				game_state.perform_preventive_maintenance(_selected_index)
				_add_recent_log("check", "예방정비 실행")
		"emergency":
			if _try_pay(action_id, "예산 부족: 긴급수리 불가"):
				game_state.perform_emergency_repair(_selected_index)
				_add_recent_log("warn", "긴급수리 실행")
		"campaign":
			if not game_state.run_safety_campaign(_selected_campaign_id):
				_add_recent_log("warn", "캠페인 적용 실패: 예산 부족")
			else:
				_add_recent_log("info", "안내 캠페인 적용")
		"upgrade": _show_upgrade_choices()

func _try_pay(action_id: String, fail_log: String) -> bool:
	if game_state.money < GameBalance.action_cost(action_id):
		_add_recent_log("warn", fail_log)
		return false
	return true

func _show_upgrade_choices() -> void:
	round_manager.stop()
	var options: Array[Dictionary] = [
		{"label": "도어 센서 개선 (-%d)" % GameBalance.upgrade_cost("door_sensor"), "upgrade_id": "door_sensor"},
		{"label": "속도 제어 드라이브 개선 (-%d)" % GameBalance.upgrade_cost("speed_drive"), "upgrade_id": "speed_drive"},
		{"label": "유지관리 패키지 적용 (-%d)" % GameBalance.upgrade_cost("maintenance_suite"), "upgrade_id": "maintenance_suite"},
		{"label": "내구성 강화 패키지 (-%d)" % GameBalance.upgrade_cost("durability_pack"), "upgrade_id": "durability_pack"},
		{"label": "수용량 최적화 (-%d)" % GameBalance.upgrade_cost("capacity_tuning"), "upgrade_id": "capacity_tuning"}
	]
	event_popup.show_event(EventData.new("upgrade_select", "업그레이드 선택", "설치할 업그레이드를 고르세요.", "normal", "action_button", options, [], [], "상황에 맞는 1개 선택", "", _selected_index + 1, "major"))

func _on_event_option_chosen(effect: Dictionary, event_data: EventData) -> void:
	if effect.has("upgrade_id"):
		var result: Dictionary = game_state.apply_upgrade_with_feedback(_selected_index, str(effect["upgrade_id"]))
		_add_recent_log("check" if bool(result.get("ok", false)) else "warn", str(result.get("message", "업그레이드 처리")))
		if bool(result.get("ok", false)) and str(effect["upgrade_id"]) == "door_sensor":
			unlock_manager.unlock_component("door_sensor")
		_refresh_all()
		round_manager.start()
		return
	if effect.has("fault_action") and event_data.target_elevator_id >= 0:
		game_state.resolve_fault_for_elevator_id(event_data.target_elevator_id, str(effect["fault_action"]))
	game_state.apply_effect(effect, event_data.target_elevator_id)
	_add_recent_log("warn", event_data.title)
	var unlocked_any: bool = false
	for cid: String in event_data.component_tags:
		if not unlock_manager.unlocked_components.has(cid):
			unlocked_any = true
		unlock_manager.unlock_component(cid)
	if not unlocked_any:
		round_manager.start()

func _populate_selector() -> void:
	elevator_selector.clear()
	for i: int in game_state.elevators.size():
		elevator_selector.add_item(game_state.elevators[i].name, i)
	elevator_selector.select(0)

func _on_elevator_selected(index: int) -> void:
	_selected_index = index
	if _tutorial_waiting_action == "select_elevator":
		_complete_tutorial_action_step()
	_refresh_right_panel()
	var elevator: ElevatorData = game_state.get_elevator(_selected_index)
	if elevator != null:
		building_view.set_selected_elevator(elevator.id)

func _complete_tutorial_action_step() -> void:
	_tutorial_waiting_action = ""
	tutorial_hint.text = "실습 완료! 다음 버튼으로 진행하세요."
	tutorial_next_button.disabled = false

func _refresh_all() -> void:
	_refresh_top_bar()
	_refresh_right_panel()
	building_view.update_demands(game_state.floor_demands)
	building_view.update_elevators(game_state.elevators, func(status: String) -> Color: return game_state.get_status_color(status))
	var elevator: ElevatorData = game_state.get_elevator(_selected_index)
	if elevator != null:
		building_view.set_selected_elevator(elevator.id)
	_render_recent_logs()

func _refresh_top_bar() -> void:
	money_value.text = "%s원" % _format_number(game_state.money)
	safety_value.text = "%.1f" % game_state.safety_score
	satisfaction_value.text = "%.1f" % game_state.satisfaction
	inspection_value.text = "%.1f%%" % game_state.inspection_rate
	complaint_value.text = str(game_state.complaints)
	time_value.text = "Day %d / Tick %d" % [game_state.day, game_state.tick_in_day]
	action_panel.set_budget(game_state.money)

func _refresh_right_panel() -> void:
	var elevator: ElevatorData = game_state.get_elevator(_selected_index)
	if elevator == null:
		return
	status_badge.text = "%s | %s" % [elevator.name, elevator.status_label()]
	status_badge.modulate = game_state.get_status_color(elevator.status)
	floor_value.text = "%d층" % elevator.current_floor
	wear_value.text = "%.1f%%" % elevator.wear
	risk_value.text = "%.1f%%" % elevator.breakdown_risk
	inspection_day_value.text = "%d일 전" % max(0, game_state.day - elevator.last_inspection_day)
	work_summary.text = "운행 요약: 목표 %d층 · 부하 %.0f%%" % [elevator.target_floor, elevator.load * 100.0]
	upgrades_value.text = "업그레이드: %s" % elevator.installed_upgrades_text()
	component_summary.text = _build_component_summary(elevator)
	campaign_summary.text = "캠페인\n%s" % "\n".join(game_state.get_campaign_status_lines())
	recommend_label.text = "⚡ 오늘 목표: %s\n권장: %s" % [str(game_state.current_goal.get("label", "-")), _build_recommendation(elevator)]

func _build_component_summary(elevator: ElevatorData) -> String:
	var keys: Array[String] = ["door_sensor", "overload_sensor", "emergency_call", "brake_system"]
	var lines: Array[String] = []
	for cid: String in keys:
		if not unlock_manager.unlocked_components.has(cid):
			continue
		lines.append("• %s  [%s]" % [game_state.component_display_name(cid), elevator.component_state_label(cid)])
	return "핵심 장치 TOP3\n" + ("\n".join(lines.slice(0, 3)) if not lines.is_empty() else "• 해금된 장치 없음")

func _build_recommendation(elevator: ElevatorData) -> String:
	if elevator.status == "fault": return "긴급수리 → 비상통화 점검"
	if game_state.day - elevator.last_inspection_day > GameState.INSPECTION_INTERVAL_DAYS: return "정기점검으로 제동·제어계 안정화"
	if elevator.wear > 70.0: return "예방정비로 마모 리스크 완화"
	if game_state.complaints > 6: return "안내강화로 혼잡 민원 우선 대응"
	return "균형 운영 유지"

func _render_recent_logs() -> void:
	for child: Node in recent_log_list.get_children(): child.queue_free()
	for entry: Dictionary in _recent_logs:
		var item: Label = Label.new()
		item.text = "%s %s" % [entry.get("icon", "•"), entry.get("text", "")]
		item.modulate = entry.get("color", Color.WHITE)
		item.theme_type_variation = "SmallLabel"
		recent_log_list.add_child(item)

func _open_codex() -> void:
	round_manager.stop()
	codex_popup.show_codex(unlock_manager.unlocked_components, GameState.COMPONENT_CATALOG, unlock_manager.earned_titles)

func _on_codex_unlocked(_component_id: String) -> void:
	_open_codex()

func _on_tutorial_next() -> void:
	if _tutorial_waiting_action != "":
		tutorial_hint.text = "먼저 안내된 실습을 완료하세요."
		return
	_tutorial_step += 1
	if _tutorial_step >= _tutorial_pages.size():
		_finish_tutorial(); return
	_render_tutorial_step()

func _on_tutorial_skip() -> void:
	_finish_tutorial()

func _render_tutorial_step() -> void:
	var page: Dictionary = _tutorial_pages[_tutorial_step]
	tutorial_title.text = "튜토리얼 - %s" % str(page.get("title", "안내"))
	tutorial_step_label.text = "%d / %d" % [_tutorial_step + 1, _tutorial_pages.size()]
	tutorial_text.text = str(page.get("body", ""))
	tutorial_next_button.text = "게임 시작" if _tutorial_step == _tutorial_pages.size() - 1 else "다음"
	_tutorial_waiting_action = str(page.get("requires_action", ""))
	tutorial_next_button.disabled = _tutorial_waiting_action != ""
	tutorial_hint.text = "실습 단계: 안내된 조작을 완료하세요." if _tutorial_waiting_action != "" else ""
	await get_tree().process_frame
	_update_tutorial_focus(str(page.get("focus", "")))

func _update_tutorial_focus(focus_id: String) -> void:
	var target: Control = $Root
	match focus_id:
		"top": target = $Root/Layout/TopBar
		"building": target = %BuildingView
		"right": target = $Root/Layout/MainRow/RightPanel
		"actions": target = %ActionPanel
		"recommend": target = %RecommendSection
		"logs": target = %RecentLogSection
	var rect: Rect2 = target.get_global_rect().grow(6)
	tutorial_focus_frame.global_position = rect.position
	tutorial_focus_frame.size = rect.size
	var full: Rect2 = Rect2(Vector2.ZERO, get_viewport_rect().size)
	dim_top.global_position = full.position
	dim_top.size = Vector2(full.size.x, max(0.0, rect.position.y))
	dim_bottom.global_position = Vector2(0, rect.end.y)
	dim_bottom.size = Vector2(full.size.x, max(0.0, full.end.y - rect.end.y))
	dim_left.global_position = Vector2(0, rect.position.y)
	dim_left.size = Vector2(max(0.0, rect.position.x), rect.size.y)
	dim_right.global_position = Vector2(rect.end.x, rect.position.y)
	dim_right.size = Vector2(max(0.0, full.end.x - rect.end.x), rect.size.y)

func _finish_tutorial() -> void:
	AppState.start_with_tutorial = false
	tutorial_overlay.visible = false
	_add_recent_log("info", "튜토리얼 종료 · Day 운영 시작")
	round_manager.start()

func _add_recent_log(level: String, msg: String) -> void:
	var icon_map: Dictionary = {"warn": "⚠", "check": "🛠", "info": "ℹ"}
	var color_map: Dictionary = {"warn": Color("#f2c14e"), "check": Color("#6ee787"), "info": Color("#61afef")}
	var safe_msg: String = msg if msg.length() <= 36 else msg.substr(0, 36) + "…"
	_recent_logs.push_front({"icon": icon_map.get(level, "ℹ"), "text": safe_msg, "color": color_map.get(level, Color.WHITE)})
	if _recent_logs.size() > GameBalance.MAX_RECENT_LOGS:
		_recent_logs.resize(GameBalance.MAX_RECENT_LOGS)

func _format_number(value: int) -> String:
	var text: String = str(value)
	var out: String = ""
	var count: int = 0
	for i: int in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0: out = "," + out
	return out
