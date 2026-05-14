extends Control

@onready var back_button := $CenterContainer/VBoxContainer/BackButton

func _ready():
	back_button.pressed.connect(_on_back)

func _on_back():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
