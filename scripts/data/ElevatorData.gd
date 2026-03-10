extends RefCounted
class_name ElevatorData

const UPGRADE_DISPLAY: Dictionary = {
	"door_sensor": "도어 센서 개선",
	"speed_drive": "속도 드라이브 개선",
	"maintenance_suite": "유지관리 효율 팩",
	"durability_pack": "내구성 강화",
	"capacity_tuning": "수용량 개선"
}

var id: int
var name: String
var current_floor: int
var target_floor: int
var status: String = "normal"
var wear: float
var breakdown_risk: float
var load: float
var age_years: int
var last_inspection_day: int
var installed_upgrades: Array[String] = []
var inspection_penalty_ticks: int = 0

var speed_factor: float = 1.0
var durability_factor: float = 1.0

var component_health: Dictionary = {
	"door_sensor": 78.0,
	"door_interlock": 80.0,
	"door_operator": 76.0,
	"overload_sensor": 79.0,
	"emergency_call": 82.0,
	"brake_system": 74.0,
	"governor": 76.0,
	"hoist_rope": 73.0,
	"guide_rail": 75.0,
	"controller": 77.0
}

func _init(p_id: int, p_name: String, p_floor: int, p_wear: float, p_risk: float, p_age: int, p_last_inspection_day: int, p_speed_factor: float = 1.0, p_durability_factor: float = 1.0) -> void:
	id = p_id
	name = p_name
	current_floor = p_floor
	target_floor = p_floor
	wear = clampf(p_wear, 0.0, 100.0)
	breakdown_risk = clampf(p_risk, 0.0, 100.0)
	load = 0.0
	age_years = p_age
	last_inspection_day = p_last_inspection_day
	speed_factor = p_speed_factor
	durability_factor = p_durability_factor

func status_label() -> String:
	match status:
		"normal": return "정상"
		"busy": return "운행중"
		"warning": return "주의"
		"risk": return "위험"
		"fault": return "고장"
		"inspection_due": return "점검필요"
		_: return "알 수 없음"

func installed_upgrades_text() -> String:
	if installed_upgrades.is_empty():
		return "없음"
	var labels: Array[String] = []
	for upgrade_id: String in installed_upgrades:
		labels.append(str(UPGRADE_DISPLAY.get(upgrade_id, "알 수 없는 업그레이드")))
	return ", ".join(labels)

func has_upgrade(upgrade_id: String) -> bool:
	return installed_upgrades.has(upgrade_id)

func degrade_component(component_id: String, amount: float) -> void:
	if not component_health.has(component_id):
		return
	var old_value: float = float(component_health[component_id])
	component_health[component_id] = clampf(old_value - amount, 0.0, 100.0)

func recover_component(component_id: String, amount: float) -> void:
	if not component_health.has(component_id):
		return
	var old_value: float = float(component_health[component_id])
	component_health[component_id] = clampf(old_value + amount, 0.0, 100.0)

func component_state_label(component_id: String) -> String:
	var v: float = float(component_health.get(component_id, 0.0))
	if v >= 70.0:
		return "정상"
	if v >= 45.0:
		return "주의"
	return "점검필요"
