class_name UIStyle
extends RefCounted
## Wspólny wygląd menu: fioletowe przyciski ze złotą ramką, napisy z obrysem.

const GOLD := Color(0.98, 0.78, 0.2)
const OUTLINE := Color(0.08, 0.04, 0.1)


static func box(bg: Color, border: Color, border_width := 1, margin := 4.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_content_margin_all(margin)
	return style


static func panel_style() -> StyleBoxFlat:
	var style := box(Color(0.16, 0.1, 0.22, 0.95), GOLD, 2, 10.0)
	return style


static func style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", box(Color(0.32, 0.22, 0.44), Color(0.55, 0.42, 0.7), 1, 3.0))
	button.add_theme_stylebox_override("hover", box(Color(0.46, 0.32, 0.62), GOLD, 1, 3.0))
	button.add_theme_stylebox_override("pressed", box(Color(0.46, 0.32, 0.62), GOLD, 1, 3.0))
	button.add_theme_stylebox_override("disabled", box(Color(0.22, 0.16, 0.2), Color(0.35, 0.28, 0.32), 1, 3.0))
	var focus := box(Color(0, 0, 0, 0), GOLD, 2, 3.0)
	focus.draw_center = false
	button.add_theme_stylebox_override("focus", focus)


static func text_settings(color := Color.WHITE, size := 16) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font_color = color
	settings.font_size = size
	settings.outline_size = 4
	settings.outline_color = OUTLINE
	return settings


static func make_button(text: String, min_width := 170.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(min_width, 0)
	style_button(button)
	return button


static func make_label(text: String, color := Color.WHITE, size := 16) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.label_settings = text_settings(color, size)
	return label
