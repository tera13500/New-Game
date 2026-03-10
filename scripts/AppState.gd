extends Node

const PIXEL_FONT_PATH: String = "res://assets/fonts/pixel_ko.ttf"

var start_with_tutorial: bool = true
var first_run: bool = true

func try_apply_pixel_font(theme: Theme) -> bool:
	if theme == null or not FileAccess.file_exists(PIXEL_FONT_PATH):
		return false
	var pixel_font: FontFile = FontFile.new()
	pixel_font.font_data = FileAccess.get_file_as_bytes(PIXEL_FONT_PATH)
	theme.default_font = pixel_font
	theme.set_font("font", "Label", pixel_font)
	theme.set_font("font", "Button", pixel_font)
	theme.set_font("font", "HeadingLabel", pixel_font)
	theme.set_font("font", "SubTitleLabel", pixel_font)
	theme.set_font("font", "SmallLabel", pixel_font)
	theme.set_font("font", "CardValueLabel", pixel_font)
	theme.set_font("font", "LogLabel", pixel_font)
	theme.set_font("font", "BadgeLabel", pixel_font)
	return true
