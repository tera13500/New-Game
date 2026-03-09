extends PanelContainer
class_name BuildingView

@onready var floor_demand_labels: Array[Label] = [%Demand5, %Demand4, %Demand3, %Demand2, %Demand1]
@onready var floor_bars: Array[ColorRect] = [%Bar5, %Bar4, %Bar3, %Bar2, %Bar1]
@onready var cab_a: PanelContainer = %CabA
@onready var cab_b: PanelContainer = %CabB
@onready var cab_a_label: Label = %CabALabel
@onready var cab_b_label: Label = %CabBLabel
@onready var marker_a: Label = %MarkerA
@onready var marker_b: Label = %MarkerB

var _floor_y: Array[float] = []

func _ready() -> void:
	_floor_y = [36.0, 128.0, 220.0, 312.0, 404.0]

func update_demands(demands: Array[int]) -> void:
	for i in min(demands.size(), floor_demand_labels.size()):
		var value: int = demands[demands.size() - 1 - i]
		floor_demand_labels[i].text = "%d명 대기" % value
		floor_demand_labels[i].modulate = Color("#FFB24D") if value >= 8 else Color("#C9D5EC")
		floor_bars[i].size.x = clampf(20 + value * 6.0, 20, 160)
		floor_bars[i].color = Color("#FF8A4C") if value >= 10 else Color("#4EA1FF")

func update_elevators(elevators: Array[ElevatorData], color_resolver: Callable) -> void:
	if elevators.size() < 2:
		return
	_update_single(cab_a, cab_a_label, marker_a, elevators[0], color_resolver)
	_update_single(cab_b, cab_b_label, marker_b, elevators[1], color_resolver)

func set_selected_elevator(elevator_id: int) -> void:
	cab_a.scale = Vector2.ONE
	cab_b.scale = Vector2.ONE
	marker_a.add_theme_color_override("font_color", Color("#D3E5FF"))
	marker_b.add_theme_color_override("font_color", Color("#D3E5FF"))
	if elevator_id == 1:
		cab_a.scale = Vector2(1.08, 1.08)
		marker_a.add_theme_color_override("font_color", Color("#FFFFFF"))
	else:
		cab_b.scale = Vector2(1.08, 1.08)
		marker_b.add_theme_color_override("font_color", Color("#FFFFFF"))

func _update_single(car: PanelContainer, label: Label, marker: Label, elevator: ElevatorData, color_resolver: Callable) -> void:
	var floor_index: int = clampi(5 - elevator.current_floor, 0, 4)
	var target_y: float = _floor_y[floor_index]
	create_tween().tween_property(car, "position:y", target_y, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	label.text = "%s  %.0f%%" % [elevator.name, elevator.load * 100.0]
	label.modulate = color_resolver.call(elevator.status)
	car.modulate = color_resolver.call(elevator.status)
	marker.text = _marker_text(elevator.status)
	marker.modulate = color_resolver.call(elevator.status)
	if elevator.status == "fault":
		var flash: Tween = create_tween()
		flash.tween_property(car, "modulate:a", 0.35, 0.1)
		flash.tween_property(car, "modulate:a", 1.0, 0.1)
	elif elevator.status in ["warning", "risk", "inspection_due"]:
		var pulse: Tween = create_tween()
		pulse.tween_property(car, "scale", Vector2(1.05, 1.05), 0.12)
		pulse.tween_property(car, "scale", Vector2.ONE, 0.12)

func _marker_text(status: String) -> String:
	match status:
		"fault": return "⛔"
		"warning": return "⚠"
		"inspection_due": return "🛠"
		"busy": return "⇅"
		_: return "●"
