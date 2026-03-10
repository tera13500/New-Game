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

var _floor_y: Array[float] = []

func _ready() -> void:
	_floor_y = [36.0, 128.0, 220.0, 312.0, 404.0]

func update_demands(demands: Array[int]) -> void:
	for i: int in min(demands.size(), floor_demand_labels.size()):
		var value: int = demands[demands.size() - 1 - i]
		floor_demand_labels[i].text = "%d층  대기 %d" % [5 - i, value]
		var warning: bool = value >= 8
		floor_demand_labels[i].modulate = Color("#f2c14e") if warning else Color("#e8eefc")
		floor_bars[i].size.x = clampf(20 + value * 6.0, 20, 160)
		floor_bars[i].color = Color("#e35d6a") if value >= 12 else (Color("#f2c14e") if warning else Color("#61afef"))
		floor_dots[i].text = "■■■■" if value >= 12 else ("■■■□" if value >= 8 else ("■■□□" if value >= 4 else "■□□□"))
		floor_dots[i].modulate = floor_bars[i].color

func update_elevators(elevators: Array[ElevatorData], color_resolver: Callable) -> void:
	if elevators.size() < 2:
		return
	_update_single(cab_a, door_a, cab_a_label, marker_a, elevators[0], color_resolver)
	_update_single(cab_b, door_b, cab_b_label, marker_b, elevators[1], color_resolver)

func set_selected_elevator(elevator_id: int) -> void:
	cab_a.scale = Vector2.ONE
	cab_b.scale = Vector2.ONE
	cab_a.self_modulate = Color.WHITE
	cab_b.self_modulate = Color.WHITE
	if elevator_id == 1:
		cab_a.scale = Vector2(1.08, 1.08)
		cab_a.self_modulate = Color("#ffffff")
		marker_a.add_theme_color_override("font_color", Color("#ffffff"))
		marker_b.add_theme_color_override("font_color", Color("#aeb8d0"))
	else:
		cab_b.scale = Vector2(1.08, 1.08)
		cab_b.self_modulate = Color("#ffffff")
		marker_b.add_theme_color_override("font_color", Color("#ffffff"))
		marker_a.add_theme_color_override("font_color", Color("#aeb8d0"))

func _update_single(car: PanelContainer, door: ColorRect, label: Label, marker: Label, elevator: ElevatorData, color_resolver: Callable) -> void:
	var floor_index: int = clampi(5 - elevator.current_floor, 0, 4)
	var target_y: float = _floor_y[floor_index]
	create_tween().tween_property(car, "position:y", target_y, 0.23).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	label.text = "%s %.0f%%" % [elevator.name, elevator.load * 100.0]
	label.modulate = Color("#e8eefc")
	car.modulate = color_resolver.call(elevator.status)
	marker.text = _marker_text(elevator.status)
	marker.modulate = color_resolver.call(elevator.status)
	if elevator.status == "busy":
		create_tween().tween_property(door, "size:x", 10.0, 0.12).tween_property(door, "size:x", 24.0, 0.12)
	elif elevator.status == "fault":
		door.color = Color("#e35d6a")
		var flash: Tween = create_tween()
		flash.tween_property(car, "modulate", Color("#e35d6a"), 0.1)
		flash.tween_property(car, "modulate", color_resolver.call(elevator.status), 0.1)
	else:
		door.color = Color(0.92, 0.98, 1, 0.6)
		door.size.x = 24

func _marker_text(status: String) -> String:
	match status:
		"fault": return "✖"
		"warning", "inspection_due", "risk": return "⚠"
		"busy": return "⇅"
		_: return "●"
