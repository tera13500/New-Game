extends Node
class_name GameState

const FLOOR_COUNT := 5
const ELEVATOR_COUNT := 2
const INSPECTION_INTERVAL_DAYS := 4

signal state_changed
signal elevator_fault(elevator_id: int)

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

func _ready() -> void:
	seed_dummy_data()

func seed_dummy_data() -> void:
	elevators.clear()
	elevators.append(ElevatorData.new(1, "A호기", 1, 25.0, 16.0, 6, 1))
	elevators.append(ElevatorData.new(2, "B호기", 4, 46.0, 34.0, 11, 3))
	floor_demands = [2, 3, 1, 4, 2]
	round_log.clear()
	round_log.append("초기 운영 상태가 설정되었습니다.")

func get_status_color(status: String) -> Color:
	match status:
		"normal":
			return Color("#2BD67B")
		"busy":
			return Color("#48B4FF")
		"warning", "inspection_due":
			return Color("#F7B538")
		"risk":
			return Color("#FF7B72")
		"fault":
			return Color("#D7263D")
		_:
			return Color("#7A8499")

func get_elevator(index: int) -> ElevatorData:
	if index < 0 or index >= elevators.size():
		return null
	return elevators[index]

func advance_tick() -> void:
	tick_in_day += 1
	_generate_demand()
	_assign_targets()
	_move_elevators()
	_update_degradation()
	_update_global_scores()
	emit_signal("state_changed")

func finish_day() -> Dictionary:
	day += 1
	tick_in_day = 0
	var avg_waiting: float = _total_demand() / float(FLOOR_COUNT)
	var summary := {
		"day": day - 1,
		"avg_waiting": avg_waiting,
		"fault_count": _count_faults(),
		"inspection_overdue": _count_inspection_due(),
		"message": _daily_message(avg_waiting)
	}
	round_log.append("Day %d 종료 - 평균 대기 %.1f" % [int(summary["day"]), avg_waiting])
	emit_signal("state_changed")
	return summary

func perform_regular_inspection(elevator_index: int) -> void:
	var elevator := get_elevator(elevator_index)
	if elevator == null:
		return
	if money < 1200:
		round_log.append("예산 부족: 정기점검 불가")
		return
	money -= 1200
	elevator.last_inspection_day = day
	elevator.breakdown_risk = maxf(0.0, elevator.breakdown_risk - 18.0)
	elevator.status = "normal"
	inspection_rate = clampf(inspection_rate + 10.0, 0.0, 100.0)
	safety_score = clampf(safety_score + 3.0, 0.0, 100.0)
	round_log.append("%s 정기점검 완료" % elevator.name)
	emit_signal("state_changed")

func perform_preventive_maintenance(elevator_index: int) -> void:
	var elevator := get_elevator(elevator_index)
	if elevator == null:
		return
	if money < 2400:
		round_log.append("예산 부족: 예방정비 불가")
		return
	money -= 2400
	elevator.wear = maxf(0.0, elevator.wear - 22.0)
	elevator.breakdown_risk = maxf(0.0, elevator.breakdown_risk - 12.0)
	safety_score = clampf(safety_score + 1.5, 0.0, 100.0)
	round_log.append("%s 예방정비 완료" % elevator.name)
	emit_signal("state_changed")

func perform_emergency_repair(elevator_index: int) -> void:
	var elevator := get_elevator(elevator_index)
	if elevator == null:
		return
	if money < 5200:
		round_log.append("예산 부족: 긴급수리 불가")
		return
	money -= 5200
	elevator.status = "warning"
	elevator.wear = maxf(10.0, elevator.wear - 14.0)
	elevator.breakdown_risk = maxf(0.0, elevator.breakdown_risk - 28.0)
	satisfaction = clampf(satisfaction + 2.0, 0.0, 100.0)
	complaints = max(0, complaints - 1)
	round_log.append("%s 긴급수리 완료" % elevator.name)
	emit_signal("state_changed")

func run_safety_campaign() -> void:
	if money < 900:
		round_log.append("예산 부족: 안내 강화 불가")
		return
	money -= 900
	satisfaction = clampf(satisfaction + 1.5, 0.0, 100.0)
	safety_score = clampf(safety_score + 1.0, 0.0, 100.0)
	complaints = max(0, complaints - 1)
	round_log.append("이용객 안내/경고 강화 캠페인 진행")
	emit_signal("state_changed")

func apply_upgrade(elevator_index: int, upgrade_id: String) -> bool:
	var elevator := get_elevator(elevator_index)
	if elevator == null:
		return false
	if elevator.has_upgrade(upgrade_id):
		return false
	var cost := 0
	match upgrade_id:
		"door_sensor":
			cost = 2600
		"speed_drive":
			cost = 2800
		"maintenance_suite":
			cost = 3000
		"durability_pack":
			cost = 3400
		"capacity_tuning":
			cost = 2800
		_:
			return false
	if money < cost:
		return false
	money -= cost
	elevator.installed_upgrades.append(upgrade_id)
	if upgrade_id == "durability_pack":
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

func _generate_demand() -> void:
	var peak_multiplier := 1.0
	if tick_in_day >= 3 and tick_in_day <= 5:
		peak_multiplier = 1.45
	for floor in FLOOR_COUNT:
		var generated := randi_range(0, 3)
		generated = int(round(generated * peak_multiplier))
		floor_demands[floor] = clampi(floor_demands[floor] + generated, 0, 28)

func _assign_targets() -> void:
	var hot_floors := _floors_by_demand_desc()
	for i in elevators.size():
		var elevator := elevators[i]
		if elevator.status == "fault":
			continue
		elevator.target_floor = hot_floors[min(i, hot_floors.size() - 1)] + 1

func _move_elevators() -> void:
	for elevator in elevators:
		if elevator.status == "fault":
			continue
		if elevator.current_floor < elevator.target_floor:
			elevator.current_floor += 1
			elevator.status = "busy"
		elif elevator.current_floor > elevator.target_floor:
			elevator.current_floor -= 1
			elevator.status = "busy"
		else:
			var floor_idx := elevator.current_floor - 1
			var throughput := 3
			if elevator.has_upgrade("capacity_tuning"):
				throughput += 2
			var served := min(floor_demands[floor_idx], throughput)
			floor_demands[floor_idx] -= served
			elevator.load = float(served) / float(max(1, throughput))
			elevator.status = "normal" if elevator.breakdown_risk < 45.0 else "warning"

func _update_degradation() -> void:
	for elevator in elevators:
		if elevator.status == "fault":
			continue
		var wear_gain := 0.8 + elevator.load * 1.2 + float(elevator.age_years) * 0.03
		if elevator.has_upgrade("maintenance_suite"):
			wear_gain *= 0.78
		elevator.wear = clampf(elevator.wear + wear_gain, 0.0, 100.0)
		var risk_gain := 0.5 + elevator.wear * 0.018
		if day - elevator.last_inspection_day > INSPECTION_INTERVAL_DAYS:
			risk_gain += 1.4
			elevator.status = "inspection_due"
		if elevator.has_upgrade("door_sensor"):
			risk_gain *= 0.9
		elevator.breakdown_risk = clampf(elevator.breakdown_risk + risk_gain, 0.0, 100.0)
		if elevator.breakdown_risk >= 88.0 and randf() < 0.12:
			elevator.status = "fault"
			complaints += 2
			satisfaction = clampf(satisfaction - 7.0, 0.0, 100.0)
			round_log.append("%s 고장 발생" % elevator.name)
			emit_signal("elevator_fault", elevator.id)

func _update_global_scores() -> void:
	var waiting := _total_demand()
	if waiting > 18:
		satisfaction = clampf(satisfaction - 1.8, 0.0, 100.0)
		complaints += 1
	if waiting > 25:
		satisfaction = clampf(satisfaction - 2.8, 0.0, 100.0)
		complaints += 1
	inspection_rate = clampf(inspection_rate - 0.6, 0.0, 100.0)
	if _count_inspection_due() > 0:
		safety_score = clampf(safety_score - 0.8, 0.0, 100.0)
	else:
		safety_score = clampf(safety_score + 0.2, 0.0, 100.0)
	if complaints > 12:
		money = max(0, money - 350)

func _floors_by_demand_desc() -> Array[int]:
	var indexes: Array[int] = []
	for idx in FLOOR_COUNT:
		indexes.append(idx)
	indexes.sort_custom(func(a: int, b: int) -> bool:
		return floor_demands[a] > floor_demands[b]
	)
	return indexes

func _total_demand() -> int:
	var total := 0
	for value in floor_demands:
		total += value
	return total

func _count_faults() -> int:
	var count := 0
	for elevator in elevators:
		if elevator.status == "fault":
			count += 1
	return count

func _count_inspection_due() -> int:
	var count := 0
	for elevator in elevators:
		if day - elevator.last_inspection_day > INSPECTION_INTERVAL_DAYS:
			count += 1
	return count

func _daily_message(avg_waiting: float) -> String:
	if _count_faults() > 0:
		return "고장 대응이 시급합니다. 긴급수리를 고려하세요."
	if avg_waiting > 5.0:
		return "혼잡이 높습니다. 예방정비 또는 속도 업그레이드를 검토하세요."
	if _count_inspection_due() > 0:
		return "정기점검 지연이 있습니다. 안전 점수 하락에 주의하세요."
	return "안정적인 운영입니다. 예산을 아껴 다음 라운드를 준비하세요."
