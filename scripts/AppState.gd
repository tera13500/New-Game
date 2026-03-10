extends Node

const UI_FONT_PATH: String = "res://assets/fonts/ui_font.ttf"

var start_with_tutorial: bool = true
var first_run: bool = true

func try_apply_ui_font(theme: Theme) -> bool:
	if theme == null:
		return false
	var ui_font: Font = _build_font_resource()
	if ui_font == null:
		return false
	theme.default_font = ui_font
	for variation: String in ["Label", "Button", "HeadingLabel", "SubTitleLabel", "SmallLabel", "CardValueLabel", "LogLabel", "BadgeLabel"]:
		theme.set_font("font", variation, ui_font)
	return true

func _build_font_resource() -> Font:
	if FileAccess.file_exists(UI_FONT_PATH):
		var file_font: FontFile = FontFile.new()
		file_font.font_data = FileAccess.get_file_as_bytes(UI_FONT_PATH)
		return file_font
	var system_font: SystemFont = SystemFont.new()
	system_font.font_names = PackedStringArray(["Noto Sans CJK KR", "Noto Sans KR", "Malgun Gothic", "Apple SD Gothic Neo", "Arial"])
	return system_font
