extends PanelContainer
class_name ActionPanel

signal action_requested(action_id: String)

func _ready() -> void:
	%InspectionButton.pressed.connect(func() -> void: emit_signal("action_requested", "inspection"))
	%PreventiveButton.pressed.connect(func() -> void: emit_signal("action_requested", "preventive"))
	%EmergencyButton.pressed.connect(func() -> void: emit_signal("action_requested", "emergency"))
	%UpgradeButton.pressed.connect(func() -> void: emit_signal("action_requested", "upgrade"))
	%CampaignButton.pressed.connect(func() -> void: emit_signal("action_requested", "campaign"))
