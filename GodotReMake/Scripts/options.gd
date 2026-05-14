extends Control

const OPTIONS_FILE := "user://options.json"

var options_data := {}

@onready var show_blood_check := $CenterContainer/VBoxContainer/GraphicsSection/ShowBloodRow/ShowBloodCheck
@onready var effects_slider := $CenterContainer/VBoxContainer/SoundSection/EffectsVolRow/EffectsVolSlider
@onready var effects_value := $CenterContainer/VBoxContainer/SoundSection/EffectsVolRow/EffectsVolValue
@onready var music_slider := $CenterContainer/VBoxContainer/SoundSection/MusicVolRow/MusicVolSlider
@onready var music_value := $CenterContainer/VBoxContainer/SoundSection/MusicVolRow/MusicVolValue
@onready var back_button := $CenterContainer/VBoxContainer/BackButton

func _ready():
	_load_options()
	_connect_buttons()
	_apply_options_to_ui()

func _connect_buttons():
	show_blood_check.toggled.connect(_on_show_blood_toggled)
	effects_slider.value_changed.connect(_on_effects_vol_changed)
	music_slider.value_changed.connect(_on_music_vol_changed)
	back_button.pressed.connect(_on_back)

func _load_options():
	if not FileAccess.file_exists(OPTIONS_FILE):
		options_data = {
			"show_blood": true,
			"effects_volume": 100,
			"music_volume": 100,
		}
		return
	var file := FileAccess.open(OPTIONS_FILE, FileAccess.READ)
	if file == null:
		options_data = {"show_blood": true, "effects_volume": 100, "music_volume": 100}
		return
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		options_data = {"show_blood": true, "effects_volume": 100, "music_volume": 100}
		return
	options_data = json.data

func _save_options():
	var file := FileAccess.open(OPTIONS_FILE, FileAccess.WRITE)
	if file == null:
		return
	var json_text := JSON.stringify(options_data, "\t", false, true)
	file.store_string(json_text)
	file.close()

func _apply_options_to_ui():
	show_blood_check.button_pressed = options_data.get("show_blood", true)
	effects_slider.value = options_data.get("effects_volume", 100)
	music_slider.value = options_data.get("music_volume", 100)
	effects_value.text = str(int(effects_slider.value))
	music_value.text = str(int(music_slider.value))

func _on_show_blood_toggled(pressed: bool):
	options_data["show_blood"] = pressed
	_save_options()

func _set_bus_volume(bus_name: String, volume: int):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume / 100.0))

func _on_effects_vol_changed(value: float):
	var int_val = int(value)
	options_data["effects_volume"] = int_val
	effects_value.text = str(int_val)
	_set_bus_volume("SFX", int_val)
	_save_options()

func _on_music_vol_changed(value: float):
	var int_val = int(value)
	options_data["music_volume"] = int_val
	music_value.text = str(int_val)
	_set_bus_volume("Music", int_val)
	_save_options()

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
