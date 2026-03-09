extends Node
class_name GameState

const FLOOR_COUNT := 5
const ELEVATOR_COUNT := 2
const INSPECTION_INTERVAL_DAYS := 4

const COMPONENT_CATALOG := {
	"door_sensor": ["도어 센서", "문 끼임을 감지해 재개방", "문사고 예방 핵심"],
	"door_interlock": ["도어 인터록", "문이 닫혀야 출발 허용", "출입부 안전 보장"],
	"door_operator": ["도어 오퍼레이터", "문 개폐 구동 장치", "문 지연/충돌 완화"],
	"overload_sensor": ["과부하 감지", "과밀 탑승 감지", "과부하 운행 방지"],
	"emergency_call": ["비상통화 장치", "비상 시 구조 요청", "고장 시 피해 완화"],
	"brake_system": ["제동장치", "정지 제어", "급정지 위험 완화"],
	"governor": ["조속기", "과속 감지", "고위험 사고 예방"],
	"hoist_rope": ["권상 로프", "카를 끌어올리는 핵심", "노후 시 진동/위험 증가"],
	"guide_rail": ["가이드레일", "카 이동 정렬", "소음/진동 억제"],
	"controller": ["제어반", "운행 로직 제어", "정지 오차/버튼 반응 개선"]
}

const CAMPAIGN_CATALOG := {
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
var active_campaign_ticks := {
	"door_safety": 0,
	"overload_notice": 0,
	"emergency_guide": 0,
	"senior_care": 0
}

var last_event_components: Array[String] = []

func _ready() -> void:
	seed_dummy_data()

func seed_dummy_data() -> void:
	elevators.clear()
	elevators.append(ElevatorData.new(1, "A호기", 1, 25.0, 16.0, 6, 1))
	elevators.append(ElevatorData.new(2, "B호기", 4, 46.0, 34.0, 11, 3))
	floor_demands = [2, 3, 1, 4, 2]
	round_log = ["초기 운영 상태가 설정되었습니다."]

func get_status_color(status: String) -> Color:
	match status:
		"normal": return Color("#2BD67B")
		"busy": return Color("#48B4FF")
		"warning", "inspection_due": return Color("#F7B538")
		"risk": return Color("#FF7B72")
		"fault": return Color("#D7263D")
		_: return Color("#7A8499")

func get_elevator(index: int) -> ElevatorData:
	if index < 0 or index >= elevators.size():
		return null
	return elevators[index]

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
	var summary := {
		"day": day,
		"avg_waiting": avg_waiting,
		"fault_count": _count_faults(),
		"inspection_overdue": _count_inspection_due(),
		"best_prevention": _best_prevention_text(),
		"critical_component": _most_critical_component_name(),
		"missed_signal": _missed_signal_text(),
		"recommendation": _next_recommendation_text(),
		"insight": _daily_insight_text(),
		"message": _daily_message(avg_waiting)
	}
	round_log.append("Day %d 종료 - 평균 대기 %.1f" % [day, avg_waiting])
	day += 1
	tick_in_day = 0
	emit_signal("state_changed")
	return summary

func perform_regular_inspection(elevator_index: int) -> void:
	var elevator := get_elevator(elevator_index)
	if elevator == null or money < 1200:
		return
	money -= 1200
	elevator.last_inspection_day = day
	elevator.breakdown_risk = maxf(0.0, elevator.breakdown_risk - 18.0)
	elevator.recover_component("brake_system", 8.0)
	elevator.recover_component("controller", 6.0)
	elevator.status = "normal"
	inspection_rate = clampf(inspection_rate + 10.0, 0.0, 100.0)
	safety_score = clampf(safety_score + 3.0, 0.0, 100.0)
	round_log.append("%s 정기점검 완료" % elevator.name)
	emit_signal("state_changed")

func perform_preventive_maintenance(elevator_index: int) -> void:
	var elevator := get_elevator(elevator_index)
	if elevator == null or money < 2400:
		return
	money -= 2400
	elevator.wear = maxf(0.0, elevator.wear - 22.0)
	elevator.breakdown_risk = maxf(0.0, elevator.breakdown_risk - 12.0)
	elevator.recover_component("door_operator", 10.0)
	elevator.recover_component("guide_rail", 10.0)
	elevator.recover_component("hoist_rope", 8.0)
	safety_score = clampf(safety_score + 1.5, 0.0, 100.0)
	round_log.append("%s 예방정비 완료" % elevator.name)
	emit_signal("state_changed")

func perform_emergency_repair(elevator_index: int) -> void:
	var elevator := get_elevator(elevator_index)
	if elevator == null or money < 5200:
		return
	money -= 5200
	elevator.status = "warning"
	elevator.wear = maxf(10.0, elevator.wear - 14.0)
	elevator.breakdown_risk = maxf(0.0, elevator.breakdown_risk - 28.0)
	elevator.recover_component("brake_system", 15.0)
	elevator.recover_component("governor", 12.0)
	satisfaction = clampf(satisfaction + 2.0, 0.0, 100.0)
	complaints = max(0, complaints - 1)
	round_log.append("%s 긴급수리 완료" % elevator.name)
	emit_signal("state_changed")

func run_safety_campaign(campaign_id: String) -> bool:
	if not CAMPAIGN_CATALOG.has(campaign_id) or money < 900:
		return false
	money -= 900
	active_campaign_ticks[campaign_id] = int(CAMPAIGN_CATALOG[campaign_id][1])
	satisfaction = clampf(satisfaction + 1.2, 0.0, 100.0)
	round_log.append("안전홍보 적용: %s" % CAMPAIGN_CATALOG[campaign_id][0])
	emit_signal("state_changed")
	return true

func apply_upgrade(elevator_index: int, upgrade_id: String) -> bool:
	var elevator := get_elevator(elevator_index)
	if elevator == null or elevator.has_upgrade(upgrade_id):
		return false
	var cost := {"door_sensor":2600, "speed_drive":2800, "maintenance_suite":3000, "durability_pack":3400, "capacity_tuning":2800}.get(upgrade_id, -1)
	if cost < 0 or money < cost:
		return false
	money -= cost
	elevator.installed_upgrades.append(upgrade_id)
	if upgrade_id == "door_sensor":
		elevator.recover_component("door_sensor", 18.0)
	if upgrade_id == "durability_pack":
		elevator.recover_component("hoist_rope", 12.0)
		elevator.breakdown_risk = maxf(0.0, elevator.breakdown_risk - 6.0)
	round_log.append("%s 업그레이드 설치: %s" % [elevator.name, upgrade_id])
	emit_signal("state_changed")
	return true

func apply_effect(effect: Dictionary) -> void:
	money += int(effect.get("money", 0))
	safety_score = clampf(safety_score + float(effect.get("safety", 0.0)), 0.0, 100.0)
	satisfaction = clampf(satisfaction + float(effect.get("satisfaction", 0.0)), 0.0, 100.0)
	complaints = max(0, complaints + int(effect.get("complaints", 0)))
	for elevator in elevators:
		elevator.breakdown_risk = clampf(elevator.breakdown_risk + float(effect.get("risk", 0.0)), 0.0, 100.0)
		elevator.wear = clampf(elevator.wear + float(effect.get("wear", 0.0)), 0.0, 100.0)
	round_log.append(str(effect.get("log", "이벤트 조치 적용")))
	emit_signal("state_changed")

func get_event_weight(event_id: String) -> float:
	var w := 1.0
	if event_id in ["door_delay", "door_sensor"] and active_campaign_ticks["door_safety"] > 0:
		w *= 0.65
	if event_id == "overload_warn" and active_campaign_ticks["overload_notice"] > 0:
		w *= 0.6
	if event_id == "fault_real" and active_campaign_ticks["emergency_guide"] > 0:
		w *= 0.75
	return w

func get_campaign_status_lines() -> Array[String]:
	var out: Array[String] = []
	for id in CAMPAIGN_CATALOG.keys():
		var left := int(active_campaign_ticks[id])
		if left > 0:
			out.append("%s (%dtick)" % [CAMPAIGN_CATALOG[id][0], left])
	if out.is_empty():
		out.append("활성 캠페인 없음")
	return out

func _tick_campaigns() -> void:
	for k in active_campaign_ticks.keys():
		if active_campaign_ticks[k] > 0:
			active_campaign_ticks[k] -= 1

func _generate_demand() -> void:
	var peak_multiplier := 1.0
	if tick_in_day >= 3 and tick_in_day <= 5:
		peak_multiplier = 1.45
	if active_campaign_ticks["senior_care"] > 0:
		peak_multiplier *= 0.92
	for floor in FLOOR_COUNT:
		var generated := int(round(randi_range(0, 3) * peak_multiplier))
		floor_demands[floor] = clampi(floor_demands[floor] + generated, 0, 28)

func _assign_targets() -> void:
	var hot := _floors_by_demand_desc()
	for i in elevators.size():
		var e := elevators[i]
		if e.status == "fault":
			continue
		e.target_floor = hot[min(i, hot.size() - 1)] + 1

func _move_elevators() -> void:
	for e in elevators:
		if e.status == "fault":
			continue
		if e.current_floor < e.target_floor:
			e.current_floor += 1
			e.status = "busy"
		elif e.current_floor > e.target_floor:
			e.current_floor -= 1
			e.status = "busy"
		else:
			var idx := e.current_floor - 1
			var throughput := 3 + (2 if e.has_upgrade("capacity_tuning") else 0)
			var served := min(floor_demands[idx], throughput)
			floor_demands[idx] -= served
			e.load = float(served) / float(max(1, throughput))
			e.status = "normal" if e.breakdown_risk < 45.0 else "warning"

func _update_degradation() -> void:
	for e in elevators:
		if e.status == "fault":
			continue
		var wear_gain := 0.8 + e.load * 1.2 + float(e.age_years) * 0.03
		if e.has_upgrade("maintenance_suite"):
			wear_gain *= 0.78
		e.wear = clampf(e.wear + wear_gain, 0.0, 100.0)
		e.degrade_component("door_operator", 0.7)
		e.degrade_component("guide_rail", 0.5)
		e.degrade_component("hoist_rope", 0.6)
		if day - e.last_inspection_day > INSPECTION_INTERVAL_DAYS:
			e.status = "inspection_due"
			for c in ["brake_system", "controller", "door_interlock"]:
				e.degrade_component(c, 0.9)
		var risk_gain := 0.45 + e.wear * 0.017
		risk_gain += _component_risk_penalty(e)
		if e.has_upgrade("door_sensor"):
			risk_gain *= 0.92
		e.breakdown_risk = clampf(e.breakdown_risk + risk_gain, 0.0, 100.0)
		if e.breakdown_risk >= 88.0 and randf() < 0.12:
			e.status = "fault"
			complaints += 2
			satisfaction = clampf(satisfaction - 7.0, 0.0, 100.0)

func _component_risk_penalty(e: ElevatorData) -> float:
	var penalty := 0.0
	for cid in e.component_health.keys():
		var h := float(e.component_health[cid])
		if h < 45.0:
			penalty += 0.45
		if h < 30.0:
			penalty += 0.65
	return penalty

func _update_global_scores() -> void:
	var waiting := _total_demand()
	if waiting > 18:
		satisfaction = clampf(satisfaction - 1.8, 0.0, 100.0)
		complaints += 1
	if waiting > 25:
		satisfaction = clampf(satisfaction - 2.8, 0.0, 100.0)
		complaints += 1
	if active_campaign_ticks["emergency_guide"] > 0:
		complaints = max(0, complaints - 1)
	inspection_rate = clampf(inspection_rate - 0.55, 0.0, 100.0)
	safety_score = clampf(safety_score - (0.8 if _count_inspection_due() > 0 else -0.2), 0.0, 100.0)
	if complaints > 12:
		money = max(0, money - 350)

func _floors_by_demand_desc() -> Array[int]:
	var idx: Array[int] = []
	for i in FLOOR_COUNT:
		idx.append(i)
	idx.sort_custom(func(a: int, b: int) -> bool: return floor_demands[a] > floor_demands[b])
	return idx

func _total_demand() -> int:
	var total := 0
	for v in floor_demands:
		total += v
	return total

func _count_faults() -> int:
	var c := 0
	for e in elevators:
		if e.status == "fault":
			c += 1
	return c

func _count_inspection_due() -> int:
	var c := 0
	for e in elevators:
		if day - e.last_inspection_day > INSPECTION_INTERVAL_DAYS:
			c += 1
	return c

func _most_critical_component_name() -> String:
	var min_h := 999.0
	var min_id := "door_sensor"
	for e in elevators:
		for cid in e.component_health.keys():
			var h := float(e.component_health[cid])
			if h < min_h:
				min_h = h
				min_id = cid
	return COMPONENT_CATALOG[min_id][0]

func _best_prevention_text() -> String:
	if active_campaign_ticks["door_safety"] > 0:
		return "문 끼임 주의 안내가 문 관련 리스크를 낮췄습니다."
	if inspection_rate > 75.0:
		return "정기점검 이행으로 고장위험 상승을 억제했습니다."
	return "예방정비 투자로 노후화 속도를 완화했습니다."

func _missed_signal_text() -> String:
	if _count_inspection_due() > 0:
		return "점검 기한 경과 호기가 있습니다."
	if complaints > 8:
		return "민원 누적 신호가 큽니다. 안내 강화가 필요합니다."
	return "큰 위험 신호는 없지만 로프/레일 노후를 주시하세요."

func _next_recommendation_text() -> String:
	if _count_faults() > 0:
		return "긴급수리 후 비상통화/제동장치 상태를 우선 점검하세요."
	if _most_critical_component_name() in ["권상 로프", "가이드레일"]:
		return "예방정비로 권상·가이드 계열 마모를 먼저 낮추세요."
	return "문/과부하 안내 캠페인으로 피크 민원을 선제 억제하세요."

func _daily_insight_text() -> String:
	return "안전은 고장 후 수리보다, 장치 상태를 미리 관리할 때 가장 크게 개선됩니다."

func _daily_message(avg_waiting: float) -> String:
	if _count_faults() > 0:
		return "고장 대응이 시급합니다."
	if avg_waiting > 5.0:
		return "혼잡이 높습니다. 속도/수용량 개선을 검토하세요."
	if _count_inspection_due() > 0:
		return "점검 지연이 안전 점수 하락을 만들고 있습니다."
	return "안정 운영 중입니다. 예방 투자로 다음 라운드를 준비하세요."
