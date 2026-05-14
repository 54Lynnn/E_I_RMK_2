extends Control

signal guide_closed()

const GUIDE_PREFIX := "res://Art/Guide/guide_"
const GUIDE_COUNT := 3

var _current_index := 0
var _guide_textures := []

@onready var _image := $CenterContainer/Panel/VBox/Image
@onready var _prev_btn := $CenterContainer/Panel/Controls/PrevButton
@onready var _next_btn := $CenterContainer/Panel/Controls/NextButton
@onready var _close_btn := $CenterContainer/Panel/Controls/CloseButton
@onready var _page_label := $CenterContainer/Panel/Controls/PageLabel

func _ready():
	_load_guides()
	_prev_btn.pressed.connect(_on_prev)
	_next_btn.pressed.connect(_on_next)
	_close_btn.pressed.connect(_on_close)
	_show_page(0)

func _load_guides():
	for i in range(1, GUIDE_COUNT + 1):
		var path := GUIDE_PREFIX + "%02d" % i + ".png"
		if ResourceLoader.exists(path):
			_guide_textures.append(load(path))
		else:
			_guide_textures.append(null)

func _show_page(index: int):
	if _guide_textures.is_empty():
		return
	_current_index = clampi(index, 0, _guide_textures.size() - 1)
	_image.texture = _guide_textures[_current_index]
	_page_label.text = "%d / %d" % [_current_index + 1, _guide_textures.size()]
	_prev_btn.disabled = _current_index <= 0
	_next_btn.disabled = _current_index >= _guide_textures.size() - 1

func _on_prev():
	_show_page(_current_index - 1)

func _on_next():
	_show_page(_current_index + 1)

func _on_close():
	if guide_closed.get_connections().size() > 0:
		guide_closed.emit()
	else:
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
