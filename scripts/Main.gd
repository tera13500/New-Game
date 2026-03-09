extends Control

@onready var game_state: GameState = $GameState

@onready var money_value: Label = %MoneyValue
@onready var safety_value: Label = %SafetyValue
@onready var satisfaction_value: Label = %SatisfactionValue
@onready var inspection_value: Label = %InspectionValue
@onready var complaint_value: Label = %ComplaintValue

@onready var elevator_option: OptionButton = %ElevatorSelector
@onready var status_badge: Label = %StatusBadge
@onready var elevator_name: Label = %ElevatorName
@onready var floor_value: Label = %CurrentFloorValue
@onready var wear_value: Label = %WearValue
@onready var risk_value: Label = %RiskValue
@onready var inspection_day_value: Label = %InspectionDayValue

func _ready() -> void:
	refresh_top_bar()
	populate_elevator_selector()
	refresh_elevator_panel(0)
	elevator_option.item_selected.connect(_on_elevator_selected)

func refresh_top_bar() -> void:
	money_value.text = "%s 원" % _format_number(game_state.money)
	safety_value.text = "%d" % game_state.safety_score
	satisfaction_value.text = "%d" % game_state.satisfaction
	inspection_value.text = "%d%%" % game_state.inspection_rate
	complaint_value.text = str(game_state.complaints)

func populate_elevator_selector() -> void:
	elevator_option.clear()
	for i in game_state.elevators.size():
		var elevator: ElevatorData = game_state.elevators[i]
		elevator_option.add_item(elevator.name, i)

func refresh_elevator_panel(index: int) -> void:
	var elevator := game_state.get_elevator(index)
	if elevator == null:
		return

	elevator_name.text = elevator.name
	status_badge.text = elevator.status_label()
	status_badge.modulate = game_state.get_status_color(elevator.status)

	floor_value.text = "%d층" % elevator.current_floor
	wear_value.text = "%.0f%%" % elevator.wear
	risk_value.text = "%.0f%%" % elevator.breakdown_risk
	inspection_day_value.text = "%d일 전" % elevator.last_inspection_day

func _on_elevator_selected(index: int) -> void:
	refresh_elevator_panel(index)

func _format_number(value: int) -> String:
	var text := str(value)
	var out := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
