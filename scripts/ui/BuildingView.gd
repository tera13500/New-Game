extends PanelContainer
class_name BuildingView

@onready var floor_demand_labels: Array[Label] = [%Demand5, %Demand4, %Demand3, %Demand2, %Demand1]
@onready var floor_bars: Array[ColorRect] = [%Bar5, %Bar4, %Bar3, %Bar2, %Bar1]
@onready var floor_dots: Array[Label] = [%Dot5, %Dot4, %Dot3, %Dot2, %Dot1]
@onready var cab_a: PanelContainer = %CabA
@onready var cab_b: PanelContainer = %CabB
@onready var door_a: ColorRect = %DoorA
@onready var door_b: ColorRect = %DoorB
@onready var cab_a_label: Label = %CabALabel
@onready var cab_b_label: Label = %CabBLabel
@onready var marker_a: Label = %MarkerA
@onready var marker_b: Label = %MarkerB
@onready var select_frame_a: ColorRect = %SelectFrameA
@onready var select_frame_b: ColorRect = %SelectFrameB

var _floor_y: Array[float] = []

func _ready() -> void:
	_floor_y = [36.0, 128.0, 220.0, 312.0, 404.0]

func update_demands(demands: Array[int]) -> void:
	for i: int in min(demands.size(), floor_demand_labels.size()):
		var value: int = demands[demands.size() - 1 - i]
		floor_demand_labels[i].text = "%d층  대기 %d명" % [5 - i, value]
		floor_bars[i].size.x = clampf(26 + value * 7.2, 26, 178)
		floor_bars[i].color = _demand_color(value)
		floor_demand_labels[i].modulate = floor_bars[i].color.lightened(0.18)
		floor_dots[i].text = "●".repeat(clampi(int(round(value / 2.5)), 0, 10))
		floor_dots[i].modulate = floor_bars[i].color

func update_elevators(elevators: Array[ElevatorData], color_resolver: Callable) -> void:
	if elevators.size() < 2:
		return
	_update_single(cab_a, door_a, cab_a_label, marker_a, elevators[0], color_resolver)
	_update_single(cab_b, door_b, cab_b_label, marker_b, elevators[1], color_resolver)

func set_selected_elevator(elevator_id: int) -> void:
	cab_a.scale = Vector2.ONE
	cab_b.scale = Vector2.ONE
	select_frame_a.visible = elevator_id == 1
	select_frame_b.visible = elevator_id == 2
	if elevator_id == 1:
		cab_a.scale = Vector2(1.06, 1.06)
	else:
		cab_b.scale = Vector2(1.06, 1.06)

func _update_single(car: PanelContainer, door: ColorRect, label: Label, marker: Label, elevator: ElevatorData, color_resolver: Callable) -> void:
	var floor_index: int = clampi(5 - elevator.current_floor, 0, 4)
	var target_y: float = _floor_y[floor_index]
	create_tween().tween_property(car, "position:y", target_y, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	label.text = "%s  LOAD %.0f%%" % [elevator.name, elevator.load * 100.0]
	car.modulate = color_resolver.call(elevator.status)
	marker.text = _marker_text(elevator.status)
	marker.modulate = color_resolver.call(elevator.status)
	if elevator.status == "busy":
		door.color = Color("#c7ecff")
		create_tween().tween_property(door, "size:x", 6.0, 0.11).tween_property(door, "size:x", 26.0, 0.13)
	elif elevator.status == "fault":
		door.color = Color("#e66b6b")
		var flash: Tween = create_tween().set_loops(2)
		flash.tween_property(car, "modulate", Color("#e66b6b"), 0.11)
		flash.tween_property(car, "modulate", color_resolver.call(elevator.status), 0.11)
	elif elevator.status == "inspecting":
		door.color = Color("#66bfff")
		create_tween().tween_property(door, "size:x", 14.0, 0.1).tween_property(door, "size:x", 23.0, 0.12)
	else:
		door.color = Color(0.89, 0.95, 1, 0.65)
		door.size.x = 24

func _demand_color(value: int) -> Color:
	if value >= 12:
		return Color("#e66b6b")
	if value >= 8:
		return Color("#f2b84b")
	if value >= 4:
		return Color("#66bfff")
	return Color("#5fd3bc")

func _marker_text(status: String) -> String:
	match status:
		"fault": return "FAULT"
		"warning", "inspection_due", "risk": return "WARN"
		"inspecting": return "CHECK"
		"busy": return "MOVE"
		_: return "OK"
