extends CanvasLayer

signal relic_ui_closed

var choices: Array = []
var is_open := false
var _is_dev_mode := false

const RARITY_COLORS := {
	RelicData.Rarity.COMMON: Color(0.7, 0.7, 0.7, 1.0),
	RelicData.Rarity.UNCOMMON: Color(0.2, 0.8, 0.2, 1.0),
	RelicData.Rarity.UNIQUE: Color(0.2, 0.5, 1.0, 1.0),
	RelicData.Rarity.RARE: Color(0.7, 0.2, 0.9, 1.0),
	RelicData.Rarity.EXCEPTIONAL: Color(1.0, 0.7, 0.1, 1.0),
}

const RARITY_NAMES := {
	RelicData.Rarity.COMMON: "Common",
	RelicData.Rarity.UNCOMMON: "Uncommon",
	RelicData.Rarity.UNIQUE: "Unique",
	RelicData.Rarity.RARE: "Rare",
	RelicData.Rarity.EXCEPTIONAL: "Exceptional",
}

func _ready():
	visible = false
	process_mode = PROCESS_MODE_WHEN_PAUSED

func _get_cards_container() -> HBoxContainer:
	return $CenterContainer/VBoxContainer/CardsContainer

func _get_vbox() -> VBoxContainer:
	return $CenterContainer/VBoxContainer

func show_choices(relic_choices: Array):
	choices = relic_choices
	is_open = true
	_is_dev_mode = false
	visible = true
	get_tree().paused = true
	_populate_cards()

func show_choices_dev(relic_choices: Array):
	choices = relic_choices
	is_open = true
	_is_dev_mode = true
	visible = true
	_populate_cards()
	_add_dev_buttons()

func hide_ui():
	is_open = false
	visible = false
	relic_ui_closed.emit()
	if not _is_dev_mode and not Global.hero_panel_is_open:
		get_tree().paused = false
	queue_free()

func _add_dev_buttons():
	var button_bar := HBoxContainer.new()
	button_bar.name = "DevButtonBar"
	button_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	button_bar.add_theme_constant_override("separation", 16)

	var skip_btn := Button.new()
	skip_btn.text = "Skip"
	skip_btn.custom_minimum_size = Vector2(200, 44)
	skip_btn.add_theme_font_size_override("font_size", 18)
	var skip_style := StyleBoxFlat.new()
	skip_style.bg_color = Color(0.4, 0.2, 0.2, 1.0)
	skip_style.corner_radius_top_left = 6
	skip_style.corner_radius_top_right = 6
	skip_style.corner_radius_bottom_left = 6
	skip_style.corner_radius_bottom_right = 6
	skip_btn.add_theme_stylebox_override("normal", skip_style)
	skip_btn.pressed.connect(_skip)
	button_bar.add_child(skip_btn)

	_get_vbox().add_child(button_bar)

func _skip():
	hide_ui()

func _populate_cards():
	var container = _get_cards_container()
	for child in container.get_children():
		child.queue_free()

	for relic in choices:
		var card = _create_card(relic)
		container.add_child(card)

func _create_card(relic: RelicData) -> Control:
	var rarity_color = RARITY_COLORS.get(relic.rarity, Color.WHITE)

	var card := Panel.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(180, 300)
	card.add_theme_stylebox_override("panel", _create_card_style(rarity_color))
	var rid = relic.id
	var rname = relic.relic_name
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_relic_selected(rid, rname)
	)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var rarity_label := Label.new()
	rarity_label.text = RARITY_NAMES.get(relic.rarity, "Unknown")
	rarity_label.add_theme_color_override("font_color", rarity_color)
	rarity_label.add_theme_font_size_override("font_size", 16)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(rarity_label)

	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_spacer)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(64, 64)
	icon_rect.size = Vector2(64, 64)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if ResourceLoader.exists(relic.icon_path):
		icon_rect.texture = load(relic.icon_path)
	else:
		var p := PlaceholderIcon.new()
		p.rarity_color = rarity_color
		icon_rect.texture = p._generate()
	var icon_hb := HBoxContainer.new()
	icon_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	icon_hb.add_child(icon_rect)
	vbox.add_child(icon_hb)

	var name_label := Label.new()
	name_label.text = relic.relic_name
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = relic.description
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	desc_label.add_theme_font_size_override("font_size", 15)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)

	var bot_spacer := Control.new()
	bot_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(bot_spacer)

	var btn_hb := HBoxContainer.new()
	btn_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hb)

	var select_btn := Button.new()
	select_btn.text = "Select"
	select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_btn.custom_minimum_size = Vector2(120, 36)
	select_btn.add_theme_font_size_override("font_size", 16)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = rarity_color
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	select_btn.add_theme_stylebox_override("normal", btn_style)
	select_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = rarity_color.lightened(0.3)
	btn_hover.corner_radius_top_left = 6
	btn_hover.corner_radius_top_right = 6
	btn_hover.corner_radius_bottom_left = 6
	btn_hover.corner_radius_bottom_right = 6
	select_btn.add_theme_stylebox_override("hover", btn_hover)

	select_btn.pressed.connect(_on_relic_selected.bind(rid, rname))

	btn_hb.add_child(select_btn)

	return card

func _on_relic_selected(relic_id: String, relic_name: String):
	print("RelicSelectUI: 选择了遗物:", relic_name, " id:", relic_id)
	RelicManager.select_relic(relic_id)
	hide_ui()

func _create_card_style(border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.14, 0.95)
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _create_button_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.border_color = Color(1, 1, 1, 0.2)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	return style

class PlaceholderIcon:
	var rarity_color := Color.WHITE
	func _generate() -> ImageTexture:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var c = rarity_color
		for y in range(64):
			for x in range(64):
				var dx = x - 32
				var dy = y - 32
				var dist = sqrt(dx * dx + dy * dy)
				if dist < 28:
					var a = 1.0 - dist / 28.0
					img.set_pixel(x, y, Color(c.r, c.g, c.b, a * 0.3))
		for r in range(12, 26, 2):
			for angle_deg in range(0, 360, 15):
				var rad = deg_to_rad(angle_deg)
				var px = 32 + cos(rad) * r
				var py = 32 + sin(rad) * r
				if px >= 0 and px < 64 and py >= 0 and py < 64:
					img.set_pixel(px, py, rarity_color)
		return ImageTexture.create_from_image(img)
