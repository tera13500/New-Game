extends PanelContainer
class_name ActionPanel

signal action_requested(action_id: String)
signal campaign_changed(campaign_id: String)
signal codex_opened

const COSTS: Dictionary = {
	"inspection": 1200,
	"preventive": 2400,
	"emergency": 5200,
	"campaign": 800,
	"upgrade": 2600
}

@onready var inspection_button: Button = %InspectionButton
@onready var preventive_button: Button = %PreventiveButton
@onready var emergency_button: Button = %EmergencyButton
@onready var upgrade_button: Button = %UpgradeButton
@onready var campaign_button: Button = %CampaignButton

func _ready() -> void:
	_setup_button(inspection_button, "정기점검", COSTS.inspection, "기본 점검으로 위험도 감소")
	_setup_button(preventive_button, "예방정비", COSTS.preventive, "마모도 개선 및 안정화")
	_setup_button(emergency_button, "긴급수리", COSTS.emergency, "고장 즉시 복구")
	_setup_button(upgrade_button, "업그레이드", COSTS.upgrade, "장치 성능 강화")
	_setup_button(campaign_button, "안내강화", COSTS.campaign, "민원/혼잡 완화 캠페인")

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
	inspection_button.disabled = money < int(COSTS.inspection)
	preventive_button.disabled = money < int(COSTS.preventive)
	emergency_button.disabled = money < int(COSTS.emergency)
	campaign_button.disabled = money < int(COSTS.campaign)
	upgrade_button.disabled = money < int(COSTS.upgrade)

func _setup_button(button: Button, label: String, cost: int, tip: String) -> void:
	button.custom_minimum_size = Vector2(0, 46)
	button.text = "%s\n₩%s" % [label, _format_number(cost)]
	button.tooltip_text = tip

func _on_campaign_selected(index: int) -> void:
	var ids: Array[String] = ["door_safety", "overload_notice", "emergency_guide", "senior_care"]
	emit_signal("campaign_changed", ids[index])

func _format_number(value: int) -> String:
	var text: String = str(value)
	var out: String = ""
	var count: int = 0
	for i: int in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
