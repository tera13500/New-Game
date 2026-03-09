extends CanvasLayer
class_name ComponentCodexPopup

func _ready() -> void:
	%CloseButton.pressed.connect(func() -> void: visible = false)
	visible = false

func show_codex(unlocked_components: Array[String], catalog: Dictionary, earned_titles: Array[String]) -> void:
	for child in %CardList.get_children():
		child.queue_free()
	for cid in unlocked_components:
		if not catalog.has(cid):
			continue
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 64)
		var vb := VBoxContainer.new()
		var title := Label.new()
		title.text = "%s  [%s]" % [catalog[cid][0], cid]
		var desc := Label.new()
		desc.text = "%s / %s" % [catalog[cid][1], catalog[cid][2]]
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(title)
		vb.add_child(desc)
		row.add_child(vb)
		%CardList.add_child(row)
	%TitleList.text = "획득 칭호: %s" % ("없음" if earned_titles.is_empty() else ", ".join(earned_titles))
	visible = true
