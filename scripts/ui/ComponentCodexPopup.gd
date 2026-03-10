extends CanvasLayer
class_name ComponentCodexPopup

signal popup_closed

func _ready() -> void:
	%CloseButton.pressed.connect(func() -> void:
		visible = false
		emit_signal("popup_closed")
	)
	visible = false

func show_codex(unlocked_components: Array[String], catalog: Dictionary, earned_titles: Array[String]) -> void:
	for child: Node in %CardList.get_children():
		child.queue_free()
	for cid: String in unlocked_components:
		if not catalog.has(cid):
			continue
		var entry: Array = catalog[cid]
		var row: PanelContainer = PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 70)
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color("#28324d")
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color("#5f7db8")
		row.add_theme_stylebox_override("panel", sb)
		var vb: VBoxContainer = VBoxContainer.new()
		var title: Label = Label.new()
		title.text = "◆ %s" % str(entry[0])
		title.theme_type_variation = "SubTitleLabel"
		var desc: Label = Label.new()
		desc.text = "%s / 역할: %s" % [str(entry[1]), str(entry[2])]
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.theme_type_variation = "SmallLabel"
		vb.add_child(title)
		vb.add_child(desc)
		row.add_child(vb)
		%CardList.add_child(row)
	%TitleList.text = "획득 칭호: %s" % ("없음" if earned_titles.is_empty() else ", ".join(earned_titles))
	%SubTitle.text = "새 장치 해금 시 운영 안정성과 선택지가 확장됩니다."
	visible = true
