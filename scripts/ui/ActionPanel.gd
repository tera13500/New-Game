extends PanelContainer
class_name ActionPanel

signal action_requested(action_id: String)
signal campaign_changed(campaign_id: String)
signal codex_opened

func _ready() -> void:
	%InspectionButton.pressed.connect(func() -> void: emit_signal("action_requested", "inspection"))
	%PreventiveButton.pressed.connect(func() -> void: emit_signal("action_requested", "preventive"))
	%EmergencyButton.pressed.connect(func() -> void: emit_signal("action_requested", "emergency"))
	%UpgradeButton.pressed.connect(func() -> void: emit_signal("action_requested", "upgrade"))
	%CampaignButton.pressed.connect(func() -> void: emit_signal("action_requested", "campaign"))
	%CodexButton.pressed.connect(func() -> void: emit_signal("codex_opened"))
	%CampaignSelector.clear()
	%CampaignSelector.add_item("문 끼임 주의", 0)
	%CampaignSelector.add_item("과밀 탑승 방지", 1)
	%CampaignSelector.add_item("비상 신고 안내", 2)
	%CampaignSelector.add_item("어린이/고령자 배려", 3)
	%CampaignSelector.item_selected.connect(_on_campaign_selected)

func _on_campaign_selected(index: int) -> void:
	var ids := ["door_safety", "overload_notice", "emergency_guide", "senior_care"]
	emit_signal("campaign_changed", ids[index])
