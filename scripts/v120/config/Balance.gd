extends RefCounted
class_name Balance

const START_BUDGET: int = 145000
const START_SAFETY: float = 84.0
const START_SATISFACTION: float = 79.0
const START_COMPLAINTS: int = 2
const START_SELF_CHECK_RATE: float = 62.0

const FLOOR_COUNT: int = 6
const DAY_TICKS: int = 16

const COSTS: Dictionary = {
	"self_check": 900,
	"preventive": 2300,
	"emergency": 5200,
	"vendor": 3900,
	"notice": 850,
	"upgrade": 3000
}

const GAME_OVER_BUDGET: int = 0
const GAME_OVER_SAFETY: float = 28.0
const GAME_OVER_COMPLAINTS: int = 24

const WARN_BUDGET: int = 7000
const WARN_SAFETY: float = 45.0
const WARN_COMPLAINTS: int = 14

static func cost(action_id: String) -> int:
	return int(COSTS.get(action_id, 0))
