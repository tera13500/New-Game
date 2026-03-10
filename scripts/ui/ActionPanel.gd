extends PanelContainer
class_name ActionPanel

signal action_requested(action_id: String)
signal campaign_changed(campaign_id: String)
signal codex_opened

@onready var inspection_button: Button = %InspectionButton
@onready var preventive_button: Button = %PreventiveButton
@onready var emergency_button: Button = %EmergencyButton
@onready var upgrade_button: Button = %UpgradeButton
@onready var campaign_button: Button = %CampaignButton

func _ready() -> void:
	_setup_button(inspection_button, "정기점검", GameBalance.action_cost("inspection"), "위험도 감소 / 점검률 회복")
	_setup_button(preventive_button, "예방정비", GameBalance.action_cost("preventive"), "마모도 감소 / 장치 안정화")
	_setup_button(emergency_button, "긴급수리", GameBalance.action_cost("emergency"), "고장 즉시 복구")
	_setup_button(upgrade_button, "업그레이드 선택", 0, "상세 비용은 선택 팝업에서 확인")
	_setup_button(campaign_button, "안내강화", GameBalance.action_cost("campaign"), "민원/혼잡 완화")

	inspection_button.pressed.connect(func() -> void: emit_signal("action_requested", "inspection"))
	preventive_button.pressed.connect(func() -> void: emit_signal("action_requested", "preventive"))
	emergency_button.pressed.connect(func() -> void: emit_signal("action_requested", "emergency"))
	upgrade_button.pressed.connect(func() -> void: emit_signal("action_requested", "upgrade"))
	campaign_button.pressed.connect(func() -> void: emit_signal("action_requested", "campaign"))
	%CodexButton.pressed.connect(func() -> void: emit_signal("codex_opened"))

	%CampaignSelector.clear()
	%CampaignSelector.add_item("문 끼임 주의 안내", 0)
	%CampaignSelector.add_item("과밀 탑승 방지 안내", 1)
	%CampaignSelector.add_item("비상 신고 안내", 2)
	%CampaignSelector.add_item("어린이·고령자 배려 안내", 3)
	%CampaignSelector.item_selected.connect(_on_campaign_selected)
	_on_campaign_selected(0)

func set_budget(money: int) -> void:
	_apply_budget_state(inspection_button, money >= GameBalance.action_cost("inspection"), GameBalance.action_cost("inspection"))
	_apply_budget_state(preventive_button, money >= GameBalance.action_cost("preventive"), GameBalance.action_cost("preventive"))
	_apply_budget_state(emergency_button, money >= GameBalance.action_cost("emergency"), GameBalance.action_cost("emergency"))
	_apply_budget_state(campaign_button, money >= GameBalance.action_cost("campaign"), GameBalance.action_cost("campaign"))
	upgrade_button.disabled = money < GameBalance.upgrade_cost("door_sensor")
	upgrade_button.tooltip_text = "업그레이드 최소 비용 ₩%s 필요" % GameText.format_number(GameBalance.upgrade_cost("door_sensor")) if upgrade_button.disabled else "상세 비용은 선택 팝업에서 확인"

func _apply_budget_state(button: Button, can_use: bool, needed: int) -> void:
	button.disabled = not can_use
	if can_use:
		return
	button.tooltip_text = "예산 부족 · 필요 금액 ₩%s" % GameText.format_number(needed)

func _setup_button(button: Button, label: String, cost: int, tip: String) -> void:
	button.custom_minimum_size = Vector2(0, 50)
	button.text = "%s\n%s" % [label, "₩%s" % GameText.format_number(cost) if cost > 0 else "상세 비용 팝업"]
	button.tooltip_text = tip

func _on_campaign_selected(index: int) -> void:
	var ids: Array[String] = ["door_safety", "overload_notice", "emergency_guide", "senior_care"]
	emit_signal("campaign_changed", ids[index])
