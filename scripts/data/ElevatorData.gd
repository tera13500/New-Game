extends RefCounted
class_name ElevatorData

# Elevator runtime data model for MVP.
var id: int
var name: String
var current_floor: int
var wear: float
var breakdown_risk: float
var status: String
var last_inspection_day: int

func _init(
	p_id: int,
	p_name: String,
	p_floor: int,
	p_wear: float,
	p_risk: float,
	p_status: String,
	p_last_inspection_day: int
) -> void:
	id = p_id
	name = p_name
	current_floor = p_floor
	wear = clampf(p_wear, 0.0, 100.0)
	breakdown_risk = clampf(p_risk, 0.0, 100.0)
	status = p_status
	last_inspection_day = p_last_inspection_day

func status_label() -> String:
	match status:
		"normal":
			return "정상"
		"warning":
			return "주의"
		"risk":
			return "위험"
		"fault":
			return "고장"
		_:
			return "알 수 없음"
