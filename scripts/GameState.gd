extends Node
class_name GameState

const GAME_VERSION: String = "1.1.12"
const FLOOR_COUNT: int = 5
const ELEVATOR_COUNT: int = 2
const INSPECTION_INTERVAL_DAYS: int = 4

const COMPONENT_CATALOG: Dictionary = {
	"door_sensor": ["도어 센서", "문 끼임을 감지해 재개방", "문사고 예방 핵심"],
	"door_interlock": ["도어 인터록", "문이 닫혀야 출발 허용", "출입부 안전 보장"],
	"door_operator": ["도어 오퍼레이터", "문 개폐 구동 장치", "문 지연/충돌 완화"],
	"overload_sensor": ["과부하 감지 장치", "과밀 탑승 감지", "과부하 운행 방지"],
	"emergency_call": ["비상통화 장치", "비상 시 구조 요청", "고장 시 피해 완화"],
	"brake_system": ["제동장치", "정지 제어", "급정지 위험 완화"],
	"governor": ["조속기", "과속 감지", "고위험 사고 예방"],
	"hoist_rope": ["권상 로프", "카를 끌어올리는 핵심", "노후 시 진동/위험 증가"],
	"guide_rail": ["가이드레일", "카 이동 정렬", "소음/진동 억제"],
	"controller": ["제어반", "운행 로직 제어", "정지 오차/버튼 반응 개선"]
}

const CAMPAIGN_CATALOG: Dictionary = {
	"door_safety": ["문 끼임 주의 안내", 3],
	"overload_notice": ["과밀 탑승 방지 안내", 3],
	"emergency_guide": ["비상 시 신고/통화 안내", 4],
	"senior_care": ["어린이·고령자 배려 안내", 3]
}

signal state_changed

var day: int = 1
var tick_in_day: int = 0
var money: int = 120000
var safety_score: float = 82.0
var satisfaction: float = 76.0
var inspection_rate: float = 68.0
var complaints: int = 4

var floor_demands: Array[int] = [0, 0, 0, 0, 0]
var elevators: Array[ElevatorData] = []
var round_log: Array[String] = []
var active_campaign_ticks: Dictionary = {"door_safety": 0, "overload_notice": 0, "emergency_guide": 0, "senior_care": 0}
var current_goal: Dictionary = {}
var no_fault_streak: int = 0
var best_no_fault_streak: int = 0

func _ready() -> void:
	seed_dummy_data()
	_roll_daily_goal()

func seed_dummy_data() -> void:
	elevators.clear()
	elevators.append(ElevatorData.new(1, "A호기", 1, 30.0, 22.0, 8, 1, 1.15, 0.9))
	elevators.append(ElevatorData.new(2, "B호기", 4, 42.0, 28.0, 10, 1, 0.92, 1.12))
	floor_demands = [2, 3, 1, 4, 2]
	round_log = ["초기 운영 상태가 설정되었습니다."]

func get_status_color(status: String) -> Color:
	match status:
		"normal": return Color("#37D4A7")
		"busy": return Color("#62C8FF")
		"warning", "inspection_due": return Color("#F3C95C")
		"inspecting": return Color("#73d2de")
		"risk": return Color("#FF9B64")
		"fault": return Color("#D7263D")
		_: return Color("#7A8499")

func component_display_name(component_id: String) -> String:
	var info: Array = COMPONENT_CATALOG.get(component_id, ["알 수 없는 장치", "", ""])
	return str(info[0])

func get_elevator(index: int) -> ElevatorData:
	if index < 0 or index >= elevators.size():
		return null
	return elevators[index]

func get_elevator_by_id(elevator_id: int) -> ElevatorData:
	for e: ElevatorData in elevators:
		if e.id == elevator_id:
			return e
	return null

func advance_tick() -> void:
	tick_in_day += 1
	_tick_campaigns()
	_generate_demand()
	_assign_targets()
	_move_elevators()
	_update_degradation()
	_update_global_scores()
	emit_signal("state_changed")

func finish_day() -> Dictionary:
	var avg_waiting: float = _total_demand() / float(FLOOR_COUNT)
	var goal_result: Dictionary = _evaluate_goal()
	var fault_count: int = _count_faults()
	if fault_count == 0:
		no_fault_streak += 1
		best_no_fault_streak = max(best_no_fault_streak, no_fault_streak)
	else:
		no_fault_streak = 0
	var milestones: Array[String] = []
	var milestone_reward: int = 0
	if no_fault_streak >= 5 and no_fault_streak % 5 == 0:
		milestones.append("무고장 %d일 연속" % no_fault_streak)
		milestone_reward += 900
	if money >= 150000:
		milestones.append("예산 150,000+ 유지")
		milestone_reward += 700
	if complaints == 0:
		milestones.append("민원 0건 유지")
		milestone_reward += 600
	if inspection_rate >= 90.0:
		milestones.append("고점검 운영 달성")
		milestone_reward += 500
	var summary: Dictionary = {
		"day": day,
		"avg_waiting": avg_waiting,
		"fault_count": fault_count,
		"inspection_overdue": _count_inspection_due(),
		"best_prevention": _best_prevention_text(),
		"critical_component": _most_critical_component_name(),
		"missed_signal": _missed_signal_text(),
		"recommendation": _next_recommendation_text(),
		"insight": _daily_insight_text(),
		"goal_text": str(current_goal.get("label", "-")),
		"goal_result": goal_result,
		"streak": no_fault_streak,
		"best_streak": best_no_fault_streak,
		"game_over_warning": _game_over_warning(),
		"milestones": milestones,
		"milestone_reward": milestone_reward
	}

	if bool(goal_result.get("success", false)):
		money += int(goal_result.get("reward", 0))
		safety_score = clampf(safety_score + 1.2, 0.0, 100.0)

	# 운영 성과 보상 루프(과하지 않게)
	if fault_count == 0:
		money += 450
	if complaints <= 3:
		money += 350
	if inspection_rate >= 78.0:
		money += 300
	if satisfaction >= 80.0:
		money += 250
	if milestone_reward > 0:
		money += milestone_reward

	day += 1
	tick_in_day = 0
	_roll_daily_goal()
	emit_signal("state_changed")
	return summary

func perform_regular_inspection(elevator_index: int) -> void:
	var elevator: ElevatorData = get_elevator(elevator_index)
	if elevator == null or money < GameBalance.action_cost("inspection"):
		return
	money -= GameBalance.action_cost("inspection")
	elevator.last_inspection_day = day
	elevator.breakdown_risk = maxf(0.0, elevator.breakdown_risk - 18.0)
	elevator.recover_component("brake_system", 8.0)
	elevator.recover_component("controller", 6.0)
	elevator.status = "inspecting"
	elevator.inspection_penalty_ticks = 2
	inspection_rate = clampf(inspection_rate + 9.0, 0.0, 100.0)
	safety_score = clampf(safety_score + 2.2, 0.0, 100.0)
	satisfaction = clampf(satisfaction - 0.8, 0.0, 100.0)
	emit_signal("state_changed")

func perform_preventive_maintenance(elevator_index: int) -> void:
	var elevator: ElevatorData = get_elevator(elevator_index)
	if elevator == null or money < GameBalance.action_cost("preventive"):
		return
	money -= GameBalance.action_cost("preventive")
	elevator.wear = maxf(0.0, elevator.wear - 25.0)
	elevator.breakdown_risk = maxf(0.0, elevator.breakdown_risk - 15.0)
	elevator.recover_component("door_operator", 10.0)
	elevator.recover_component("guide_rail", 10.0)
	elevator.recover_component("hoist_rope", 8.0)
	safety_score = clampf(safety_score + 2.0, 0.0, 100.0)
	emit_signal("state_changed")

func perform_emergency_repair(elevator_index: int) -> void:
	var elevator: ElevatorData = get_elevator(elevator_index)
	if elevator == null or money < GameBalance.action_cost("emergency"):
		return
	_resolve_fault_for_elevator(elevator, "immediate")
	emit_signal("state_changed")

func resolve_fault_for_elevator_id(elevator_id: int, mode: String) -> bool:
	var target: ElevatorData = get_elevator_by_id(elevator_id)
	if target == null:
		return false
	_resolve_fault_for_elevator(target, mode)
	emit_signal("state_changed")
	return true

func _resolve_fault_for_elevator(elevator: ElevatorData, mode: String) -> void:
	match mode:
		"immediate":
			if money < GameBalance.action_cost("emergency"):
				return
			money -= GameBalance.action_cost("emergency")
			elevator.status = "warning"
			elevator.wear = maxf(8.0, elevator.wear - 18.0)
			elevator.breakdown_risk = maxf(0.0, elevator.breakdown_risk - 32.0)
			elevator.recover_component("brake_system", 15.0)
			elevator.recover_component("governor", 12.0)
			elevator.recover_component("emergency_call", 8.0)
			satisfaction = clampf(satisfaction + 2.8, 0.0, 100.0)
			complaints = max(0, complaints - 2)
		"delay":
			elevator.status = "warning"
			elevator.breakdown_risk = clampf(elevator.breakdown_risk + 6.0, 0.0, 100.0)
			complaints += 1
		"outsource":
			if money < GameBalance.action_cost("fault_outsource"):
				return
			money -= GameBalance.action_cost("fault_outsource")
			elevator.status = "warning"
			elevator.wear = maxf(12.0, elevator.wear - 10.0)
			elevator.breakdown_risk = maxf(0.0, elevator.breakdown_risk - 14.0)
			elevator.recover_component("emergency_call", 6.0)
			satisfaction = clampf(satisfaction + 0.5, 0.0, 100.0)

func run_safety_campaign(campaign_id: String) -> bool:
	if not CAMPAIGN_CATALOG.has(campaign_id) or money < GameBalance.action_cost("campaign"):
		return false
	money -= GameBalance.action_cost("campaign")
	var config: Array = CAMPAIGN_CATALOG[campaign_id]
	active_campaign_ticks[campaign_id] = int(config[1])
	satisfaction = clampf(satisfaction + 1.2, 0.0, 100.0)
	emit_signal("state_changed")
	return true

func apply_upgrade(elevator_index: int, upgrade_id: String) -> bool:
	var elevator: ElevatorData = get_elevator(elevator_index)
	if elevator == null or elevator.has_upgrade(upgrade_id):
		return false
	var cost: int = GameBalance.upgrade_cost(upgrade_id)
	if cost < 0 or money < cost:
		return false
	money -= cost
	elevator.installed_upgrades.append(upgrade_id)
	match upgrade_id:
		"door_sensor": elevator.recover_component("door_sensor", 18.0)
		"durability_pack":
			elevator.recover_component("hoist_rope", 12.0)
			elevator.durability_factor *= 1.08
		"speed_drive": elevator.speed_factor *= 1.08
	emit_signal("state_changed")
	return true
func apply_upgrade_with_feedback(elevator_index: int, upgrade_id: String) -> Dictionary:
	var elevator: ElevatorData = get_elevator(elevator_index)
	if elevator == null:
		return {"ok": false, "message": "업그레이드 실패: 대상 호기를 찾을 수 없습니다."}
	if elevator.has_upgrade(upgrade_id):
		return {"ok": false, "message": "업그레이드 실패: 이미 설치된 항목입니다."}
	var cost: int = GameBalance.upgrade_cost(upgrade_id)
	if cost < 0:
		return {"ok": false, "message": "업그레이드 실패: 적용할 수 없는 항목입니다."}
	if money < cost:
		return {"ok": false, "message": "업그레이드 실패: 예산이 부족합니다."}
	var ok: bool = apply_upgrade(elevator_index, upgrade_id)
	if not ok:
		return {"ok": false, "message": "업그레이드 실패: 시스템 처리 중 오류가 발생했습니다."}
	return {"ok": true, "message": "업그레이드 적용 완료"}


func apply_effect(effect: Dictionary, target_elevator_id: int = -1) -> void:
	money += int(effect.get("money", 0))
	safety_score = clampf(safety_score + float(effect.get("safety", 0.0)), 0.0, 100.0)
	satisfaction = clampf(satisfaction + float(effect.get("satisfaction", 0.0)), 0.0, 100.0)
	complaints = max(0, complaints + int(effect.get("complaints", 0)))
	if target_elevator_id >= 0:
		var target: ElevatorData = get_elevator_by_id(target_elevator_id)
		if target != null:
			target.breakdown_risk = clampf(target.breakdown_risk + float(effect.get("risk", 0.0)), 0.0, 100.0)
			target.wear = clampf(target.wear + float(effect.get("wear", 0.0)), 0.0, 100.0)
	else:
		for elevator: ElevatorData in elevators:
			elevator.breakdown_risk = clampf(elevator.breakdown_risk + float(effect.get("risk", 0.0)), 0.0, 100.0)
			elevator.wear = clampf(elevator.wear + float(effect.get("wear", 0.0)), 0.0, 100.0)
	emit_signal("state_changed")

func get_event_weight(event_id: String) -> float:
	var w: float = 1.0
	if event_id in ["door_delay", "door_sensor"] and int(active_campaign_ticks["door_safety"]) > 0:
		w *= 0.62
	if event_id == "overload_warn" and int(active_campaign_ticks["overload_notice"]) > 0:
		w *= 0.58
	if event_id == "fault_real" and int(active_campaign_ticks["emergency_guide"]) > 0:
		w *= 0.72
	return w

func get_campaign_status_lines() -> Array[String]:
	var out: Array[String] = []
	for id: String in CAMPAIGN_CATALOG.keys():
		var left: int = int(active_campaign_ticks[id])
		if left > 0:
			var cfg: Array = CAMPAIGN_CATALOG[id]
			out.append("%s (%dt)" % [str(cfg[0]), left])
	if out.is_empty():
		out.append("활성 캠페인 없음")
	return out

func _tick_campaigns() -> void:
	for k: String in active_campaign_ticks.keys():
		if int(active_campaign_ticks[k]) > 0:
			active_campaign_ticks[k] = int(active_campaign_ticks[k]) - 1

func _generate_demand() -> void:
	var peak_multiplier: float = 1.0
	if tick_in_day >= 4 and tick_in_day <= 8:
		peak_multiplier = 1.45
	var day_pressure: float = 1.0 + min(0.35, float(day - 1) * 0.03)
	if int(active_campaign_ticks["senior_care"]) > 0:
		peak_multiplier *= 0.92
	for floor: int in FLOOR_COUNT:
		var generated: int = int(round(randi_range(0, 3) * peak_multiplier * day_pressure))
		floor_demands[floor] = clampi(floor_demands[floor] + generated, 0, 32)

func _assign_targets() -> void:
	var hot: Array[int] = _floors_by_demand_desc()
	for i: int in elevators.size():
		var e: ElevatorData = elevators[i]
		if e.status == "fault":
			continue
		e.target_floor = hot[min(i, hot.size() - 1)] + 1

func _move_elevators() -> void:
	for e: ElevatorData in elevators:
		if e.status == "fault":
			continue
		if e.inspection_penalty_ticks > 0:
			e.inspection_penalty_ticks -= 1
			e.status = "inspecting"
			if e.inspection_penalty_ticks <= 0:
				e.status = "normal"
			continue
		var step: int = 2 if e.speed_factor > 1.08 and randf() < 0.45 else 1
		if e.current_floor < e.target_floor:
			e.current_floor = min(e.target_floor, e.current_floor + step)
			e.status = "busy"
		elif e.current_floor > e.target_floor:
			e.current_floor = max(e.target_floor, e.current_floor - step)
			e.status = "busy"
		else:
			var idx: int = e.current_floor - 1
			var throughput: int = 3 + (2 if e.has_upgrade("capacity_tuning") else 0)
			throughput = int(round(float(throughput) * e.speed_factor))
			var served: int = min(floor_demands[idx], throughput)
			floor_demands[idx] -= served
			e.load = float(served) / float(max(1, throughput))
			e.status = "normal" if e.breakdown_risk < 45.0 else "warning"

func _update_degradation() -> void:
	for e: ElevatorData in elevators:
		if e.status == "fault":
			continue
		var wear_gain: float = (0.8 + e.load * 1.2 + float(e.age_years) * 0.03 + float(day - 1) * 0.02) / e.durability_factor
		if e.has_upgrade("maintenance_suite"):
			wear_gain *= 0.78
		e.wear = clampf(e.wear + wear_gain, 0.0, 100.0)
		e.degrade_component("door_operator", 0.7)
		e.degrade_component("guide_rail", 0.5)
		e.degrade_component("hoist_rope", 0.6)
		if day - e.last_inspection_day > INSPECTION_INTERVAL_DAYS:
			e.status = "inspection_due"
			for c: String in ["brake_system", "controller", "door_interlock"]:
				e.degrade_component(c, 0.9)
		var risk_gain: float = 0.45 + e.wear * 0.017
		risk_gain += _component_risk_penalty(e)
		if e.has_upgrade("door_sensor"):
			risk_gain *= 0.92
		e.breakdown_risk = clampf(e.breakdown_risk + risk_gain, 0.0, 100.0)
		if e.breakdown_risk >= GameBalance.FAULT_RISK_THRESHOLD and randf() < 0.12:
			e.status = "fault"
			complaints += 2
			satisfaction = clampf(satisfaction - 7.0, 0.0, 100.0)

func _component_risk_penalty(e: ElevatorData) -> float:
	var penalty: float = 0.0
	for cid: String in e.component_health.keys():
		var h: float = float(e.component_health[cid])
		if h < 45.0:
			penalty += 0.45
		if h < 30.0:
			penalty += 0.65
	return penalty

func _update_global_scores() -> void:
	var waiting: int = _total_demand()
	if waiting > 18:
		satisfaction = clampf(satisfaction - 1.8, 0.0, 100.0)
		complaints += 1
	if waiting > 25:
		satisfaction = clampf(satisfaction - 2.8, 0.0, 100.0)
		complaints += 1
	if int(active_campaign_ticks["emergency_guide"]) > 0:
		complaints = max(0, complaints - 1)
	inspection_rate = clampf(inspection_rate - 0.45, 0.0, 100.0)
	if _count_inspection_due() > 0:
		safety_score = clampf(safety_score - 0.55, 0.0, 100.0)
	if _count_inspecting() > 0:
		satisfaction = clampf(satisfaction - 0.35 * _count_inspecting(), 0.0, 100.0)
	else:
		safety_score = clampf(safety_score - 0.02, 0.0, 100.0)
	if complaints > 12:
		money = max(0, money - 350)

func _roll_daily_goal() -> void:
	var goals: Array[Dictionary] = [
		{"id":"fault_zero", "label":"오늘 fault 0건 유지", "reward":2200},
		{"id":"complaints_low", "label":"민원 3건 이하 유지", "reward":1900},
		{"id":"inspection_push", "label":"점검률 80 이상 달성", "reward":2000},
		{"id":"wear_control", "label":"A호기 마모도 60 이하", "reward":2000},
		{"id":"budget_150k", "label":"예산 150,000 이상 유지", "reward":2400},
		{"id":"complaint_zero_streak", "label":"민원 0 상태 유지", "reward":2300}
	]
	current_goal = goals[randi_range(0, goals.size() - 1)]

func _evaluate_goal() -> Dictionary:
	var success: bool = false
	var goal_id: String = str(current_goal.get("id", ""))
	match goal_id:
		"fault_zero": success = _count_faults() == 0
		"complaints_low": success = complaints <= 3
		"inspection_push": success = inspection_rate >= 80.0
		"wear_control":
			var a: ElevatorData = get_elevator_by_id(1)
			success = a != null and a.wear <= 60.0
		"budget_150k": success = money >= 150000
		"complaint_zero_streak": success = complaints <= 0
	return {"success": success, "reward": int(current_goal.get("reward", 0))}

func _floors_by_demand_desc() -> Array[int]:
	var idx: Array[int] = []
	for i: int in FLOOR_COUNT:
		idx.append(i)
	idx.sort_custom(func(a: int, b: int) -> bool: return floor_demands[a] > floor_demands[b])
	return idx

func _total_demand() -> int:
	var total: int = 0
	for v: int in floor_demands:
		total += v
	return total

func _count_faults() -> int:
	var c: int = 0
	for e: ElevatorData in elevators:
		if e.status == "fault":
			c += 1
	return c

func _count_inspection_due() -> int:
	var c: int = 0
	for e: ElevatorData in elevators:
		if day - e.last_inspection_day > INSPECTION_INTERVAL_DAYS:
			c += 1
	return c

func _count_inspecting() -> int:
	var c: int = 0
	for e: ElevatorData in elevators:
		if e.status == "inspecting" or e.inspection_penalty_ticks > 0:
			c += 1
	return c

func _most_critical_component_name() -> String:
	var min_h: float = 999.0
	var min_id: String = "door_sensor"
	for e: ElevatorData in elevators:
		for cid: String in e.component_health.keys():
			var h: float = float(e.component_health[cid])
			if h < min_h:
				min_h = h
				min_id = cid
	return component_display_name(min_id)

func _best_prevention_text() -> String:
	if int(active_campaign_ticks["door_safety"]) > 0:
		return "문 끼임 주의 안내가 문 관련 리스크를 낮췄습니다."
	if inspection_rate > 75.0:
		return "정기점검 이행으로 고장위험 상승을 억제했습니다."
	return "예방정비 투자로 노후화 속도를 완화했습니다."

func _missed_signal_text() -> String:
	if _count_inspection_due() > 0:
		return "점검 기한 경과 호기가 있습니다."
	if complaints > 8:
		return "민원 누적 신호가 큽니다. 안내 강화가 필요합니다."
	return "큰 위험 신호는 없지만 권상 로프/가이드레일 노후를 주시하세요."

func _next_recommendation_text() -> String:
	if _count_faults() > 0:
		return "긴급수리 후 비상통화 장치와 제동장치를 우선 점검하세요."
	if _most_critical_component_name() in ["권상 로프", "가이드레일"]:
		return "예방정비로 권상·가이드 계열 마모를 먼저 낮추세요."
	return "문/과부하 안내 캠페인으로 피크 민원을 선제 억제하세요."

func _daily_insight_text() -> String:
	return "고장 후 수리보다 취약 부품을 미리 보강할 때 안전 성과가 크게 향상됩니다."


func _game_over_warning() -> String:
	if money <= GameBalance.WARNING_MONEY:
		return "경고: 예산이 매우 낮습니다."
	if safety_score < GameBalance.WARNING_SAFETY:
		return "경고: 안전 점수가 위험 구간입니다."
	if complaints >= GameBalance.WARNING_COMPLAINTS:
		return "경고: 민원이 폭주 중입니다."
	return "안정 운영 중"

func is_game_over() -> bool:
	return money <= GameBalance.GAME_OVER_MONEY or safety_score <= GameBalance.GAME_OVER_SAFETY or complaints >= GameBalance.GAME_OVER_COMPLAINTS

func game_over_reason() -> String:
	if money <= GameBalance.GAME_OVER_MONEY:
		return "예산이 소진되어 운영을 지속할 수 없습니다."
	if safety_score <= GameBalance.GAME_OVER_SAFETY:
		return "안전 점수가 임계치 아래로 하락했습니다."
	if complaints >= GameBalance.GAME_OVER_COMPLAINTS:
		return "민원이 통제 불가능한 수준으로 누적되었습니다."
	return "운영 실패"
