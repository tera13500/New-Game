extends Node
class_name GameState

const FLOOR_COUNT := 5
const ELEVATOR_COUNT := 2

var money: int = 120000
var safety_score: int = 82
var satisfaction: int = 76
var inspection_rate: int = 68
var complaints: int = 4

var elevators: Array[ElevatorData] = []

func _ready() -> void:
	seed_dummy_data()

func seed_dummy_data() -> void:
	elevators.clear()
	elevators.append(ElevatorData.new(1, "A호기", 2, 28.0, 20.0, "normal", 3))
	elevators.append(ElevatorData.new(2, "B호기", 4, 57.0, 46.0, "warning", 6))

func get_elevator(index: int) -> ElevatorData:
	if index < 0 or index >= elevators.size():
		return null
	return elevators[index]

func get_status_color(status: String) -> Color:
	match status:
		"normal":
			return Color("#2BD67B")
		"warning":
			return Color("#F7B538")
		"risk":
			return Color("#FF7B72")
		"fault":
			return Color("#D7263D")
		_:
			return Color("#7A8499")
