extends PanelContainer
class_name BuildingView

@onready var floor_demand_labels: Array[Label] = [
	%Demand5, %Demand4, %Demand3, %Demand2, %Demand1
]
@onready var cab_a: PanelContainer = %CabA
@onready var cab_b: PanelContainer = %CabB
@onready var cab_a_label: Label = %CabALabel
@onready var cab_b_label: Label = %CabBLabel

var _floor_y: Array[float] = []

func _ready() -> void:
	_floor_y = [40.0, 135.0, 230.0, 325.0, 420.0] # 5층 -> 1층

func update_demands(demands: Array[int]) -> void:
	for i in min(demands.size(), floor_demand_labels.size()):
		floor_demand_labels[i].text = "대기 %d" % demands[demands.size() - 1 - i]
		var value := demands[demands.size() - 1 - i]
		floor_demand_labels[i].modulate = Color("#FFB24D") if value >= 8 else Color("#C9D5EC")

func update_elevators(elevators: Array[ElevatorData], color_resolver: Callable) -> void:
	if elevators.size() < 2:
		return
	_update_single(cab_a, cab_a_label, elevators[0], color_resolver)
	_update_single(cab_b, cab_b_label, elevators[1], color_resolver)

func _update_single(car: PanelContainer, label: Label, elevator: ElevatorData, color_resolver: Callable) -> void:
	var floor_index := clampi(5 - elevator.current_floor, 0, 4)
	var target_y := _floor_y[floor_index]
	var tween := create_tween()
	tween.tween_property(car, "position:y", target_y, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	label.text = "%s  %s" % [elevator.name, elevator.status_label()]
	label.modulate = color_resolver.call(elevator.status)
	car.modulate = color_resolver.call(elevator.status)
	if elevator.status == "fault":
		var flash := create_tween()
		flash.tween_property(car, "modulate:a", 0.4, 0.12)
		flash.tween_property(car, "modulate:a", 1.0, 0.12)
