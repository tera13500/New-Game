extends Control
class_name GameController

@onready var building_view: BuildingViewV120 = %BuildingView
@onready var action_bar: ActionBar = %ActionBar
@onready var tick_timer: Timer = %TickTimer
@onready var elevator_selector: OptionButton = %ElevatorSelector

var day: int = 1
var tick: int = 0
var budget: int = Balance.START_BUDGET
var safety: float = Balance.START_SAFETY
var satisfaction: float = Balance.START_SATISFACTION
var complaints: int = Balance.START_COMPLAINTS
var self_check_rate: float = Balance.START_SELF_CHECK_RATE
var selected_id: int = 1
var floor_demands: Array[int] = []
var elevators: Array[ElevatorState] = []
var logs: Array[Dictionary] = []
var streak_no_fault: int = 0
var milestones: Array[String] = []

var tutorial_steps: Array[Dictionary] = [
	{"title":"당신의 역할", "body":"당신은 관리주체의 승강기 안전관리자입니다.", "focus":"top"},
	{"title":"핵심 행동", "body":"자체점검과 예방정비로 위험을 낮추고 민원을 관리하세요.", "focus":"actions"},
	{"title":"실습 1", "body":"[자체점검]을 1회 실행하세요.", "requires":"self_check"},
	{"title":"실습 2", "body":"호기 선택을 B호기로 변경하세요.", "requires":"select_b"},
	{"title":"운영 시작", "body":"이제 Day 운영을 시작합니다.", "focus":"building"}
]
var tutorial_index: int = 0
var tutorial_wait: String = ""

func _ready() -> void:
	%VersionLabel.text = "v%s" % Terms.VERSION
	floor_demands = [2, 3, 2, 4, 3, 5]
	elevators = [
		ElevatorState.new(1, "A호기", 1, 28.0, 18.0),
		ElevatorState.new(2, "B호기", 4, 31.0, 21.0)
	]
	elevator_selector.add_item("A호기", 1)
	elevator_selector.add_item("B호기", 2)
	elevator_selector.item_selected.connect(_on_select_changed)
	building_view.elevator_selected.connect(_on_building_select)
	action_bar.action_pressed.connect(_on_action_pressed)
	%Speed1x.pressed.connect(func() -> void: _set_speed(1.1, %Speed1x))
	%Speed2x.pressed.connect(func() -> void: _set_speed(0.7, %Speed2x))
	%Speed3x.pressed.connect(func() -> void: _set_speed(0.42, %Speed3x))
	%EventOkButton.pressed.connect(func() -> void: _hide_event_popup())
	%ReportNextButton.pressed.connect(func() -> void: _hide_report_popup())
	%GameOverRetryButton.pressed.connect(func() -> void: get_tree().reload_current_scene())
	%GameOverTitleButton.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/v120/TitleScreen.tscn"))
	%TutorialNextButton.pressed.connect(_on_tutorial_next)
	%TutorialSkipButton.pressed.connect(_finish_tutorial)
	tick_timer.timeout.connect(_on_tick)
	_set_speed(1.1, %Speed1x)
	_add_log("info", "운행상태 초기화 완료")
	_refresh_ui()
	if AppState.start_with_tutorial:
		_show_tutorial()
	else:
		tick_timer.start()

func _on_tick() -> void:
	tick += 1
	_generate_demand()
	_move_elevators()
	_update_risk_scores()
	if randf() < 0.25:
		_spawn_event_hint()
	if is_game_over():
		_show_game_over()
		return
	if tick >= Balance.DAY_TICKS:
		_finish_day()
	_refresh_ui()

func _on_action_pressed(action_id: String) -> void:
	if tutorial_wait != "" and tutorial_wait == action_id:
		tutorial_wait = ""
		%TutorialHint.text = "실습 완료. 다음으로 진행하세요."
		%TutorialNextButton.disabled = false
	if budget < Balance.cost(action_id):
		_add_log("warn", "예산 부족: %s" % Terms.ACTION_LABELS[action_id])
		return
	var e: ElevatorState = _selected_elevator()
	match action_id:
		"self_check":
			budget -= Balance.cost(action_id)
			e.inspect_penalty_ticks = 2
			e.status = "inspecting"
			e.last_self_check_day = day
			self_check_rate = clampf(self_check_rate + 8.0, 0, 100)
			e.risk = maxf(0, e.risk - 10.0)
			satisfaction = clampf(satisfaction - 0.6, 0, 100)
			_add_log("check", "%s 자체점검 수행" % e.name)
		"preventive":
			budget -= Balance.cost(action_id)
			e.wear = maxf(0, e.wear - 18)
			e.risk = maxf(0, e.risk - 14)
			safety = clampf(safety + 1.1, 0, 100)
			_add_log("check", "%s 예방정비 완료" % e.name)
		"emergency":
			budget -= Balance.cost(action_id)
			e.status = "normal"
			e.risk = maxf(0, e.risk - 24)
			complaints = max(0, complaints - 2)
			satisfaction = clampf(satisfaction + 1.8, 0, 100)
			_add_log("warn", "%s 긴급보수 완료" % e.name)
		"vendor":
			budget -= Balance.cost(action_id)
			e.status = "normal"
			e.wear = maxf(0, e.wear - 10)
			e.risk = maxf(0, e.risk - 16)
			_add_log("info", "유지관리업체 현장 대응")
		"notice":
			budget -= Balance.cost(action_id)
			complaints = max(0, complaints - 1)
			satisfaction = clampf(satisfaction + 0.9, 0, 100)
			_add_log("info", "안전안내 강화 시행")
		"upgrade":
			budget -= Balance.cost(action_id)
			e.capacity_bonus += 1
			e.speed_bonus += 0.05
			_add_log("check", "%s 설비개선 적용" % e.name)
	_refresh_ui()

func _move_elevators() -> void:
	for e: ElevatorState in elevators:
		if e.inspect_penalty_ticks > 0:
			e.inspect_penalty_ticks -= 1
			e.status = "inspecting"
			if e.inspect_penalty_ticks == 0:
				e.status = "normal"
			continue
		if e.status == "fault":
			continue
		e.target_floor = _highest_demand_floor()
		if e.current_floor < e.target_floor:
			e.current_floor += 1
			e.status = "busy"
		elif e.current_floor > e.target_floor:
			e.current_floor -= 1
			e.status = "busy"
		else:
			var i: int = e.current_floor - 1
			var capacity: int = 4 + e.capacity_bonus
			var served: int = min(floor_demands[i], capacity)
			floor_demands[i] -= served
			e.load = float(served) / float(max(1, capacity))
			e.status = "warning" if e.risk > 70 else "normal"

func _update_risk_scores() -> void:
	self_check_rate = clampf(self_check_rate - 0.25, 0, 100)
	for e: ElevatorState in elevators:
		if e.status == "fault":
			complaints += 1
			satisfaction = clampf(satisfaction - 1.4, 0, 100)
			continue
		e.wear = clampf(e.wear + 0.55 + e.load * 1.1, 0, 100)
		e.risk = clampf(e.risk + 0.4 + e.wear * 0.01, 0, 100)
		if day - e.last_self_check_day > 4:
			e.status = "self_check_due"
			safety = clampf(safety - 0.35, 0, 100)
		if e.risk >= 92 and randf() < 0.2:
			e.status = "fault"
			_add_log("warn", "%s 운행중지 발생" % e.name)
	var waiting_total: int = 0
	for d: int in floor_demands:
		waiting_total += d
	if waiting_total > 30:
		complaints += 1
		satisfaction = clampf(satisfaction - 1.1, 0, 100)
	if complaints > 15:
		budget = max(0, budget - 280)

func _generate_demand() -> void:
	for i: int in Balance.FLOOR_COUNT:
		var pressure: float = 1.0 + min(0.4, float(day - 1) * 0.03)
		floor_demands[i] = clampi(floor_demands[i] + int(randi_range(0, 3) * pressure), 0, 24)

func _spawn_event_hint() -> void:
	var lines: Array[String] = [
		"정기검사 도래 30일 전: 수검 준비 상태를 확인하세요.",
		"비상통화장치 점검 이력 누락 경고가 접수되었습니다.",
		"출입문 잠금장치 오동작 민원 1건이 접수되었습니다.",
		"유지관리업체 월간 보수 이력 제출 요청이 도착했습니다."
	]
	_show_event_popup(lines[randi_range(0, lines.size() - 1)])

func _finish_day() -> void:
	tick = 0
	day += 1
	var fault_count: int = 0
	for e: ElevatorState in elevators:
		if e.status == "fault":
			fault_count += 1
	if fault_count == 0:
		streak_no_fault += 1
	else:
		streak_no_fault = 0
	if streak_no_fault > 0 and streak_no_fault % 3 == 0:
		milestones.append("무고장 %d일 연속" % streak_no_fault)
		budget += 1200
	if self_check_rate >= 85.0:
		milestones.append("자체점검 우수 이행")
		budget += 800
	_show_report_popup()

func _refresh_ui() -> void:
	%BudgetValue.text = "₩%s" % format_number(budget)
	%SafetyValue.text = "%.1f" % safety
	%SatisfactionValue.text = "%.1f" % satisfaction
	%CheckRateValue.text = "%.1f%%" % self_check_rate
	%ComplaintValue.text = str(complaints)
	%TimeValue.text = "Day %d / Tick %d" % [day, tick]
	var e: ElevatorState = _selected_elevator()
	%SelectedStatus.text = "%s | %s" % [e.name, Terms.STATUS_LABELS.get(e.status, "정상")]
	%SelectedMetrics.text = "마모 %.1f%% · 위험 %.1f%% · 현재 %d층" % [e.wear, e.risk, e.current_floor]
	%RecommendValue.text = _recommend_text(e)
	%GoalValue.text = _goal_text()
	%ComponentValue.text = "\n".join(_component_lines(e))
	_render_logs()
	action_bar.set_budget(budget)
	building_view.update_view(floor_demands, elevators, selected_id)

func _component_lines(e: ElevatorState) -> Array[String]:
	var out: Array[String] = []
	for i: int in min(3, Terms.COMPONENTS.size()):
		var level: String = "정상"
		if e.risk > 78 and i == 0:
			level = "점검 필요"
		elif e.risk > 64 and i <= 1:
			level = "주의"
		out.append("• %s [%s]" % [Terms.COMPONENTS[i], level])
	return out

func _goal_text() -> String:
	if day <= 3:
		return "민원 4건 이하 유지"
	if day <= 6:
		return "자체점검 이행률 80% 달성"
	return "운행중지 0건 유지"

func _recommend_text(e: ElevatorState) -> String:
	if e.status == "fault":
		return "긴급보수 또는 유지관리업체 호출"
	if e.status == "self_check_due":
		return "자체점검 우선 실행"
	if e.wear > 72:
		return "예방정비로 마모 완화"
	if complaints > 8:
		return "안전안내 강화 시행"
	return "균형 운영 유지"

func _render_logs() -> void:
	for child: Node in %RecentLogList.get_children():
		child.queue_free()
	for item_data: Dictionary in logs:
		var row: Label = Label.new()
		row.theme_type_variation = "LogLabel"
		row.text = "%s %s" % [item_data["icon"], item_data["text"]]
		row.modulate = item_data["color"]
		%RecentLogList.add_child(row)

func _add_log(level: String, text: String) -> void:
	var icon_map: Dictionary = {"info":"●", "check":"■", "warn":"▲"}
	var color_map: Dictionary = {"info":Color("#66bfff"), "check":Color("#7fdc8a"), "warn":Color("#f2b84b")}
	logs.push_front({"icon": icon_map.get(level, "●"), "text": text, "color": color_map.get(level, Color.WHITE)})
	if logs.size() > 5:
		logs.resize(5)

func _on_select_changed(index: int) -> void:
	selected_id = 1 if index == 0 else 2
	if tutorial_wait == "select_b" and selected_id == 2:
		tutorial_wait = ""
		%TutorialHint.text = "실습 완료. 다음으로 진행하세요."
		%TutorialNextButton.disabled = false
	_refresh_ui()

func _on_building_select(elevator_id: int) -> void:
	selected_id = elevator_id
	elevator_selector.select(0 if elevator_id == 1 else 1)
	_refresh_ui()

func _selected_elevator() -> ElevatorState:
	for e: ElevatorState in elevators:
		if e.id == selected_id:
			return e
	return elevators[0]

func _highest_demand_floor() -> int:
	var max_idx: int = 0
	for i: int in floor_demands.size():
		if floor_demands[i] > floor_demands[max_idx]:
			max_idx = i
	return max_idx + 1

func _set_speed(interval: float, active: Button) -> void:
	tick_timer.wait_time = interval
	for b: Button in [%Speed1x, %Speed2x, %Speed3x]:
		b.disabled = b == active

func _show_event_popup(message: String) -> void:
	tick_timer.stop()
	%EventMessage.text = message
	%EventPopup.visible = true

func _hide_event_popup() -> void:
	%EventPopup.visible = false
	if not %TutorialOverlay.visible:
		tick_timer.start()

func _show_report_popup() -> void:
	tick_timer.stop()
	%ReportSummary.text = "핵심 결과\n- 무고장 연속: %d일\n- 마일스톤: %s\n- 다음 권장: %s" % [streak_no_fault, "없음" if milestones.is_empty() else milestones[-1], _recommend_text(_selected_elevator())]
	%ReportPopup.visible = true

func _hide_report_popup() -> void:
	%ReportPopup.visible = false
	if not is_game_over():
		tick_timer.start()

func is_game_over() -> bool:
	return budget <= Balance.GAME_OVER_BUDGET or safety <= Balance.GAME_OVER_SAFETY or complaints >= Balance.GAME_OVER_COMPLAINTS

func _show_game_over() -> void:
	tick_timer.stop()
	%GameOverReason.text = _game_over_reason()
	%GameOverPopup.visible = true

func _game_over_reason() -> String:
	if budget <= Balance.GAME_OVER_BUDGET:
		return "예산이 소진되어 안전관리 업무를 지속할 수 없습니다."
	if safety <= Balance.GAME_OVER_SAFETY:
		return "안전도가 임계치 아래로 하락하여 운행을 지속할 수 없습니다."
	return "민원이 폭주하여 운영 신뢰도가 붕괴되었습니다."

func _show_tutorial() -> void:
	%TutorialOverlay.visible = true
	tutorial_index = 0
	_apply_tutorial_step()

func _on_tutorial_next() -> void:
	if tutorial_wait != "":
		%TutorialHint.text = "먼저 안내된 실습을 완료하세요."
		return
	tutorial_index += 1
	if tutorial_index >= tutorial_steps.size():
		_finish_tutorial()
		return
	_apply_tutorial_step()

func _apply_tutorial_step() -> void:
	var step: Dictionary = tutorial_steps[tutorial_index]
	%TutorialTitle.text = step.get("title", "안내")
	%TutorialBody.text = step.get("body", "")
	tutorial_wait = str(step.get("requires", ""))
	%TutorialHint.text = ""
	%TutorialNextButton.disabled = tutorial_wait != ""

func _finish_tutorial() -> void:
	tutorial_wait = ""
	%TutorialOverlay.visible = false
	tick_timer.start()

static func format_number(value: int) -> String:
	var text: String = str(value)
	var out: String = ""
	var count: int = 0
	for i: int in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
