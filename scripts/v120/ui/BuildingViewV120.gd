extends PanelContainer
class_name BuildingViewV120

signal elevator_selected(elevator_id: int)

@onready var demand_labels: Array[Label] = [%Demand6, %Demand5, %Demand4, %Demand3, %Demand2, %Demand1]
@onready var crowd_bars: Array[ColorRect] = [%Crowd6, %Crowd5, %Crowd4, %Crowd3, %Crowd2, %Crowd1]
@onready var car_a: PanelContainer = %CarA
@onready var car_b: PanelContainer = %CarB
@onready var door_a: ColorRect = %DoorA
@onready var door_b: ColorRect = %DoorB
@onready var badge_a: Label = %BadgeA
@onready var badge_b: Label = %BadgeB
@onready var select_a: ColorRect = %SelectA
@onready var select_b: ColorRect = %SelectB

var _floor_y: Array[float] = [40.0, 112.0, 184.0, 256.0, 328.0, 400.0]

func update_view(demands: Array[int], elevators: Array[ElevatorState], selected_id: int) -> void:
	for i: int in min(demands.size(), demand_labels.size()):
		var value: int = demands[demands.size() - 1 - i]
		demand_labels[i].text = "%d층 대기 %d명" % [demands.size() - i, value]
		crowd_bars[i].size.x = clampf(30 + value * 6.0, 30, 180)
		crowd_bars[i].color = _demand_color(value)
	_update_car(car_a, door_a, badge_a, elevators[0])
	_update_car(car_b, door_b, badge_b, elevators[1])
	select_a.visible = selected_id == elevators[0].id
	select_b.visible = selected_id == elevators[1].id

func _update_car(car: PanelContainer, door: ColorRect, badge: Label, e: ElevatorState) -> void:
	var idx: int = clampi(6 - e.current_floor, 0, 5)
	create_tween().tween_property(car, "position:y", _floor_y[idx], 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	badge.text = Terms.STATUS_LABELS.get(e.status, "정상")
	if e.status == "busy":
		door.color = Color("#8fd7ff")
		create_tween().tween_property(door, "size:x", 8.0, 0.08).tween_property(door, "size:x", 30.0, 0.12)
	elif e.status == "fault":
		door.color = Color("#e66b6b")
		create_tween().tween_property(car, "modulate", Color("#ffaaaa"), 0.1).tween_property(car, "modulate", Color.WHITE, 0.1)
	elif e.status == "inspecting":
		door.color = Color("#66bfff")
		create_tween().tween_property(door, "size:x", 15.0, 0.1).tween_property(door, "size:x", 26.0, 0.1)
	else:
		door.color = Color("#dcecff")
		door.size.x = 28

func _demand_color(v: int) -> Color:
	if v >= 12:
		return Color("#e66b6b")
	if v >= 8:
		return Color("#f2b84b")
	if v >= 4:
		return Color("#66bfff")
	return Color("#5fd3bc")

func _on_select_a_pressed() -> void:
	emit_signal("elevator_selected", 1)

func _on_select_b_pressed() -> void:
	emit_signal("elevator_selected", 2)
