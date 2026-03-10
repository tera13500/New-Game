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
@onready var recent_log_label: Label = %RecentLogLabel

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
var _recent_logs: Array[String] = []
var _recent_event_ids: Array[String] = []
var _tutorial_step: int = 0
var _tutorial_pages: Array[Dictionary] = [
	{"title":"목표", "body":"고장을 줄이고 안전점수·만족도를 지키며 민원을 관리하세요.\n오늘 목표를 달성하면 추가 예산을 획득합니다."},
	{"title":"상단 자원 카드", "body":"예산·안전·만족·점검률·민원·진행 시간을 확인합니다.\n수치가 급격히 흔들리면 하단 액션으로 즉시 대응하세요."},
	{"title":"중앙 BuildingView", "body":"층별 대기량과 A/B 호기 위치를 보여줍니다.\n붉은 상태 마커는 즉시 개입이 필요한 고장/위험 신호입니다."},
	{"title":"우측 상태 패널", "body":"선택 호기의 현재 층, 마모도, 위험도, 점검 경과를 확인합니다.\n핵심 장치/캠페인/권장 액션 순서로 우선순위를 정하세요."},
	{"title":"하단 액션 버튼", "body":"정기점검, 예방정비, 긴급수리, 업그레이드, 안내강화를 실행합니다.\n즉각 리스크 대응은 긴급수리, 장기 안정화는 점검/정비가 핵심입니다."},
	{"title":"오늘 목표", "body":"우측 패널의 오늘 목표와 권장 액션을 먼저 읽고 행동하세요.\n목표 실패보다 고장 방지가 항상 우선입니다."},
	{"title":"이벤트 처리", "body":"Major 이벤트만 팝업으로 뜨고, Minor/Info는 최근 로그에 자동 기록됩니다.\n같은 경고는 연속 팝업을 억제해 운영 집중도를 유지합니다."},
	{"title":"시작 준비 완료", "body":"이제 게임을 시작합니다.\n로그를 보며 작은 신호를 먼저 잡으면 안정 운영이 쉬워집니다."}
]

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
		_event_cooldown_ticks = 3
		_recent_event_ids.push_front(event_data.event_id)
		if _recent_event_ids.size() > 5:
			_recent_event_ids.resize(5)
		round_manager.stop()
		event_popup.show_event(event_data)
	else:
		_apply_minor_event(event_data)

func _can_show_major_popup(event_data: EventData) -> bool:
	if _major_event_count_day >= 1 and event_data.event_id != "fault_real":
		return false
	if _recent_event_ids.has(event_data.event_id):
		return false
	return true

func _apply_minor_event(event_data: EventData) -> void:
	if event_data.options.size() > 0:
		var first_option: Dictionary = event_data.options[0]
		var effect: Dictionary = first_option.get("effect", {})
		game_state.apply_effect(effect, event_data.target_elevator_id)
	var level: String = "info" if event_data.severity == "normal" else "warn"
	_add_recent_log(level, "%s 자동 처리" % event_data.title)

func _on_day_finished() -> void:
	round_manager.stop()
	_major_event_count_day = 0
	_recent_event_ids.clear()
	unlock_manager.evaluate_titles(game_state)
	var summary: Dictionary = game_state.finish_day()
	report_popup.show_report(summary, game_state)

func _on_action_requested(action_id: String) -> void:
	match action_id:
		"inspection":
			game_state.perform_regular_inspection(_selected_index)
			_add_recent_log("check", "정기점검 실행")
		"preventive":
			game_state.perform_preventive_maintenance(_selected_index)
			_add_recent_log("check", "예방정비 실행")
		"emergency":
			game_state.perform_emergency_repair(_selected_index)
			_add_recent_log("warn", "긴급수리 실행")
		"campaign":
			if not game_state.run_safety_campaign(_selected_campaign_id):
				_add_recent_log("warn", "캠페인 적용 실패: 예산 부족")
			else:
				_add_recent_log("info", "안내 캠페인 적용")
		"upgrade": _show_upgrade_choices()

func _show_upgrade_choices() -> void:
	round_manager.stop()
	var options: Array[Dictionary] = [
		{"label": "도어 센서 개선 (-2600)", "upgrade_id": "door_sensor"},
		{"label": "속도 제어 드라이브 개선 (-2800)", "upgrade_id": "speed_drive"},
		{"label": "유지관리 패키지 적용 (-3000)", "upgrade_id": "maintenance_suite"},
		{"label": "내구성 강화 패키지 (-3400)", "upgrade_id": "durability_pack"},
		{"label": "수용량 최적화 (-2800)", "upgrade_id": "capacity_tuning"}
	]
	var popup_event: EventData = EventData.new("upgrade_select", "업그레이드 선택", "설치할 업그레이드를 고르세요.", "normal", "action_button", options, [], [], "상황에 맞는 1개 선택", "", _selected_index + 1, "major")
	event_popup.show_event(popup_event)

func _on_event_option_chosen(effect: Dictionary, event_data: EventData) -> void:
	if effect.has("upgrade_id"):
		var result: Dictionary = game_state.apply_upgrade_with_feedback(_selected_index, str(effect["upgrade_id"]))
		if not bool(result.get("ok", false)):
			_add_recent_log("warn", str(result.get("message", "업그레이드 적용 실패")))
		else:
			_add_recent_log("check", "업그레이드 적용 완료")
		if bool(result.get("ok", false)) and str(effect["upgrade_id"]) == "door_sensor":
			unlock_manager.unlock_component("door_sensor")
		_refresh_all()
		round_manager.start()
		return

	if effect.has("fault_action") and event_data.target_elevator_id >= 0:
		game_state.resolve_fault_for_elevator_id(event_data.target_elevator_id, str(effect["fault_action"]))
		game_state.apply_effect(effect, event_data.target_elevator_id)
	else:
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
		var elevator: ElevatorData = game_state.elevators[i]
		elevator_selector.add_item(elevator.name, i)
	elevator_selector.select(0)

func _on_elevator_selected(index: int) -> void:
	_selected_index = index
	_refresh_right_panel()
	var elevator: ElevatorData = game_state.get_elevator(_selected_index)
	if elevator != null:
		building_view.set_selected_elevator(elevator.id)

func _refresh_all() -> void:
	_refresh_top_bar()
	_refresh_right_panel()
	building_view.update_demands(game_state.floor_demands)
	building_view.update_elevators(game_state.elevators, func(status: String) -> Color:
		return game_state.get_status_color(status)
	)
	var elevator: ElevatorData = game_state.get_elevator(_selected_index)
	if elevator != null:
		building_view.set_selected_elevator(elevator.id)
	recent_log_label.text = "최근 로그\n" + "\n".join(_recent_logs)

func _refresh_top_bar() -> void:
	money_value.text = "%s원" % _format_number(game_state.money)
	safety_value.text = "%.1f" % game_state.safety_score
	satisfaction_value.text = "%.1f" % game_state.satisfaction
	inspection_value.text = "%.1f%%" % game_state.inspection_rate
	complaint_value.text = str(game_state.complaints)
	time_value.text = "Day %d / Tick %d" % [game_state.day, game_state.tick_in_day]

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
	work_summary.text = "운행 요약: 목표 %d층 · 부하 %.0f%% · 속도 %.2f · 내구 %.2f" % [elevator.target_floor, elevator.load * 100.0, elevator.speed_factor, elevator.durability_factor]
	upgrades_value.text = "업그레이드: %s" % elevator.installed_upgrades_text()
	component_summary.text = _build_component_summary(elevator)
	campaign_summary.text = "캠페인\n%s" % "\n".join(game_state.get_campaign_status_lines())
	var goal_label: String = str(game_state.current_goal.get("label", "-"))
	recommend_label.text = "오늘 목표: %s\n권장 액션: %s" % [goal_label, _build_recommendation(elevator)]

func _build_component_summary(elevator: ElevatorData) -> String:
	var keys: Array[String] = ["door_sensor", "overload_sensor", "emergency_call", "brake_system"]
	var lines: Array[String] = []
	for cid: String in keys:
		if not unlock_manager.unlocked_components.has(cid):
			continue
		var component_name: String = game_state.component_display_name(cid)
		var state: String = elevator.component_state_label(cid)
		lines.append("- %s: %s" % [component_name, state])
	if lines.is_empty():
		return "핵심 장치\n- 해금된 장치 없음"
	return "핵심 장치\n" + "\n".join(lines)

func _build_recommendation(elevator: ElevatorData) -> String:
	if elevator.status == "fault":
		return "긴급수리 후 비상통화 장치 점검"
	if game_state.day - elevator.last_inspection_day > GameState.INSPECTION_INTERVAL_DAYS:
		return "정기점검으로 제동·제어계 안정화"
	if elevator.component_state_label("door_sensor") != "정상":
		return "도어 센서 정비 + 문 끼임 주의 안내"
	if elevator.wear > 70.0:
		return "예방정비로 마모 및 고장 위험 완화"
	if game_state.complaints > 6:
		return "안내강화 + 속도 개선으로 민원 대응"
	return "피크 시간 대비 균형 운영 유지"

func _open_codex() -> void:
	round_manager.stop()
	codex_popup.show_codex(unlock_manager.unlocked_components, GameState.COMPONENT_CATALOG, unlock_manager.earned_titles)

func _on_codex_unlocked(_component_id: String) -> void:
	_open_codex()

func _on_tutorial_next() -> void:
	_tutorial_step += 1
	if _tutorial_step >= _tutorial_pages.size():
		_finish_tutorial()
		return
	_render_tutorial_step()

func _on_tutorial_skip() -> void:
	_finish_tutorial()

func _render_tutorial_step() -> void:
	var page: Dictionary = _tutorial_pages[_tutorial_step]
	tutorial_title.text = "튜토리얼 - %s" % str(page.get("title", "안내"))
	tutorial_step_label.text = "%d / %d" % [_tutorial_step + 1, _tutorial_pages.size()]
	tutorial_text.text = str(page.get("body", ""))
	tutorial_next_button.text = "게임 시작" if _tutorial_step == _tutorial_pages.size() - 1 else "다음"

func _finish_tutorial() -> void:
	AppState.start_with_tutorial = false
	tutorial_overlay.visible = false
	_add_recent_log("info", "튜토리얼 종료 · Day 운영 시작")
	round_manager.start()

func _add_recent_log(level: String, msg: String) -> void:
	var prefix_map: Dictionary = {
		"warn": "[경고]",
		"check": "[점검]",
		"info": "[정보]"
	}
	var safe_msg: String = msg
	if safe_msg.length() > 34:
		safe_msg = safe_msg.substr(0, 34) + "…"
	_recent_logs.push_front("%s %s" % [prefix_map.get(level, "[정보]"), safe_msg])
	if _recent_logs.size() > 5:
		_recent_logs.resize(5)

func _format_number(value: int) -> String:
	var text: String = str(value)
	var out: String = ""
	var count: int = 0
	for i: int in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
