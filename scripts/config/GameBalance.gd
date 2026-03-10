extends RefCounted
class_name GameBalance

const ACTION_COSTS: Dictionary = {
	"inspection": 1200,
	"preventive": 2400,
	"emergency": 5200,
	"campaign": 800
}

const UPGRADE_COSTS: Dictionary = {
	"door_sensor": 2600,
	"speed_drive": 2800,
	"maintenance_suite": 3000,
	"durability_pack": 3400,
	"capacity_tuning": 2800
}

const EVENT_TRIGGER_CHANCE: float = 0.52
const MAX_MAJOR_EVENTS_PER_DAY: int = 1
const EVENT_COOLDOWN_TICKS: int = 3
const MAX_RECENT_LOGS: int = 5
const MAX_RECENT_EVENT_MEMORY: int = 6
const FAULT_RISK_THRESHOLD: float = 88.0

static func action_cost(action_id: String) -> int:
	return int(ACTION_COSTS.get(action_id, 0))

static func upgrade_cost(upgrade_id: String) -> int:
	return int(UPGRADE_COSTS.get(upgrade_id, -1))
