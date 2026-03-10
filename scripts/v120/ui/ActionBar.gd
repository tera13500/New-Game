extends PanelContainer
class_name ActionBar

signal action_pressed(action_id: String)

func _ready() -> void:
	%SelfCheckButton.pressed.connect(func() -> void: emit_signal("action_pressed", "self_check"))
	%PreventiveButton.pressed.connect(func() -> void: emit_signal("action_pressed", "preventive"))
	%EmergencyButton.pressed.connect(func() -> void: emit_signal("action_pressed", "emergency"))
	%VendorButton.pressed.connect(func() -> void: emit_signal("action_pressed", "vendor"))
	%NoticeButton.pressed.connect(func() -> void: emit_signal("action_pressed", "notice"))
	%UpgradeButton.pressed.connect(func() -> void: emit_signal("action_pressed", "upgrade"))

func set_budget(money: int) -> void:
	for pair: Array in [
		[%SelfCheckButton, Balance.cost("self_check")],
		[%PreventiveButton, Balance.cost("preventive")],
		[%EmergencyButton, Balance.cost("emergency")],
		[%VendorButton, Balance.cost("vendor")],
		[%NoticeButton, Balance.cost("notice")],
		[%UpgradeButton, Balance.cost("upgrade")]
	]:
		var button: Button = pair[0]
		var cost: int = pair[1]
		button.disabled = money < cost
		button.text = "%s\n₩%s" % [button.text.split("\n")[0], GameController.format_number(cost)]
