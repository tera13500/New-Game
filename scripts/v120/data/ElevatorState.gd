extends RefCounted
class_name ElevatorState

var id: int
var name: String
var current_floor: int
var target_floor: int
var load: float = 0.0
var wear: float
var risk: float
var status: String = "normal"
var last_self_check_day: int = 1
var inspect_penalty_ticks: int = 0
var capacity_bonus: int = 0
var speed_bonus: float = 1.0

func _init(p_id: int, p_name: String, p_floor: int, p_wear: float, p_risk: float) -> void:
	id = p_id
	name = p_name
	current_floor = p_floor
	target_floor = p_floor
	wear = p_wear
	risk = p_risk
