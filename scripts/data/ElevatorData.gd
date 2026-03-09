extends RefCounted
class_name ElevatorData

# Runtime data for each elevator car.
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

func _init(
	p_id: int,
	p_name: String,
	p_floor: int,
	p_wear: float,
	p_risk: float,
	p_age: int,
	p_last_inspection_day: int
) -> void:
	id = p_id
	name = p_name
	current_floor = p_floor
	target_floor = p_floor
	wear = clampf(p_wear, 0.0, 100.0)
	breakdown_risk = clampf(p_risk, 0.0, 100.0)
	load = 0.0
	age_years = p_age
	last_inspection_day = p_last_inspection_day

func status_label() -> String:
	match status:
		"normal":
			return "정상"
		"busy":
			return "운행중"
		"warning":
			return "주의"
		"risk":
			return "위험"
		"fault":
			return "고장"
		"inspection_due":
			return "점검필요"
		_:
			return "알 수 없음"

func installed_upgrades_text() -> String:
	if installed_upgrades.is_empty():
		return "없음"
	return ", ".join(installed_upgrades)

func has_upgrade(upgrade_id: String) -> bool:
	return installed_upgrades.has(upgrade_id)
