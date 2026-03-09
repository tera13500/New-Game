extends Control

@onready var game_state: GameState = $GameState
@onready var event_manager: EventManager = $EventManager
@onready var round_manager: RoundManager = $RoundManager

@onready var building_view: BuildingView = %BuildingView
@onready var action_panel: ActionPanel = %ActionPanel
@onready var event_popup: EventPopup = %EventPopup
@onready var report_popup: RoundReportPopup = %RoundReportPopup

@onready var money_value: Label = %MoneyValue
@onready var safety_value: Label = %SafetyValue
@onready var satisfaction_value: Label = %SatisfactionValue
@onready var inspection_value: Label = %InspectionValue
@onready var complaint_value: Label = %ComplaintValue
@onready var time_value: Label = %TimeValue

@onready var elevator_selector: OptionButton = %ElevatorSelector
@onready var status_badge: Label = %StatusBadge
@onready var work_summary: Label = %WorkSummary
@onready var floor_value: Label = %CurrentFloorValue
@onready var wear_value: Label = %WearValue
@onready var risk_value: Label = %RiskValue
@onready var inspection_day_value: Label = %InspectionDayValue
@onready var upgrades_value: Label = %UpgradesValue
@onready var recommend_label: Label = %RecommendLabel

var _selected_index: int = 0

func _ready() -> void:
	randomize()
	_connect_signals()
	_populate_selector()
	_refresh_all()
	round_manager.start()

func _connect_signals() -> void:
	round_manager.tick_advanced.connect(_on_tick)
	round_manager.day_finished.connect(_on_day_finished)
	action_panel.action_requested.connect(_on_action_requested)
	elevator_selector.item_selected.connect(_on_elevator_selected)
	event_popup.option_chosen.connect(_on_event_option_chosen)
	report_popup.continue_pressed.connect(func() -> void: round_manager.start())
	game_state.state_changed.connect(_refresh_all)

func _on_tick() -> void:
	game_state.advance_tick()
	var event_data := event_manager.get_event_for_state(game_state)
	if event_data != null:
		round_manager.stop()
		event_popup.show_event(event_data)

func _on_day_finished() -> void:
	round_manager.stop()
	var summary := game_state.finish_day()
	report_popup.show_report(summary, game_state)

func _on_action_requested(action_id: String) -> void:
	match action_id:
		"inspection":
			game_state.perform_regular_inspection(_selected_index)
		"preventive":
			game_state.perform_preventive_maintenance(_selected_index)
		"emergency":
			game_state.perform_emergency_repair(_selected_index)
		"campaign":
			game_state.run_safety_campaign()
		"upgrade":
			_show_upgrade_choices()

func _show_upgrade_choices() -> void:
	var options: Array[Dictionary] = [
		{"label": "문 센서 개선 (-2600)", "upgrade_id": "door_sensor"},
		{"label": "속도 드라이브 개선 (-2800)", "upgrade_id": "speed_drive"},
		{"label": "유지관리 효율 팩 (-3000)", "upgrade_id": "maintenance_suite"},
		{"label": "내구성 강화 (-3400)", "upgrade_id": "durability_pack"},
		{"label": "수용량 개선 (-2800)", "upgrade_id": "capacity_tuning"}
	]
	var popup_event := EventData.new(
		"upgrade_select",
		"업그레이드 선택",
		"선택한 엘리베이터에 설치할 업그레이드를 고르세요.",
		"normal",
		"action_button",
		[]
	)
	for option in options:
		var upgrade_id := str(option["upgrade_id"])
		popup_event.options.append({
			"label": str(option["label"]),
			"effect": {"log": "업그레이드 선택 시도"},
			"upgrade_id": upgrade_id
		})
	event_popup.show_event(popup_event)

func _on_event_option_chosen(effect: Dictionary) -> void:
	if effect.has("upgrade_id"):
		var ok := game_state.apply_upgrade(_selected_index, str(effect["upgrade_id"]))
		if not ok:
			game_state.round_log.append("업그레이드 실패: 예산 부족 또는 중복")
			_refresh_all()
		return
	game_state.apply_effect(effect)
	round_manager.start()

func _populate_selector() -> void:
	elevator_selector.clear()
	for i in game_state.elevators.size():
		elevator_selector.add_item(game_state.elevators[i].name, i)
	elevator_selector.select(0)

func _on_elevator_selected(index: int) -> void:
	_selected_index = index
	_refresh_right_panel()

func _refresh_all() -> void:
	_refresh_top_bar()
	_refresh_right_panel()
	building_view.update_demands(game_state.floor_demands)
	building_view.update_elevators(game_state.elevators, func(status: String) -> Color:
		return game_state.get_status_color(status)
	)

func _refresh_top_bar() -> void:
	money_value.text = "%s원" % _format_number(game_state.money)
	safety_value.text = "%.1f" % game_state.safety_score
	satisfaction_value.text = "%.1f" % game_state.satisfaction
	inspection_value.text = "%.1f%%" % game_state.inspection_rate
	complaint_value.text = str(game_state.complaints)
	time_value.text = "Day %d / Tick %d" % [game_state.day, game_state.tick_in_day]

func _refresh_right_panel() -> void:
	var elevator := game_state.get_elevator(_selected_index)
	if elevator == null:
		return
	status_badge.text = "%s | %s" % [elevator.name, elevator.status_label()]
	status_badge.modulate = game_state.get_status_color(elevator.status)
	floor_value.text = "%d층" % elevator.current_floor
	wear_value.text = "%.1f%%" % elevator.wear
	risk_value.text = "%.1f%%" % elevator.breakdown_risk
	inspection_day_value.text = "%d일 전" % (game_state.day - elevator.last_inspection_day)
	work_summary.text = "목표층 %d층, 현재부하 %.0f%%" % [elevator.target_floor, elevator.load * 100.0]
	upgrades_value.text = elevator.installed_upgrades_text()
	recommend_label.text = _build_recommendation(elevator)

func _build_recommendation(elevator: ElevatorData) -> String:
	if elevator.status == "fault":
		return "권장: 긴급수리를 우선 실행하세요."
	if game_state.day - elevator.last_inspection_day > GameState.INSPECTION_INTERVAL_DAYS:
		return "권장: 정기점검이 지연되었습니다."
	if elevator.wear > 70.0 or elevator.breakdown_risk > 65.0:
		return "권장: 예방정비 또는 내구성 업그레이드가 필요합니다."
	if game_state.complaints > 8:
		return "권장: 안내 강화로 민원 상승을 억제하세요."
	return "권장: 현재 상태 양호. 예산을 아껴 다음 라운드를 준비하세요."

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
