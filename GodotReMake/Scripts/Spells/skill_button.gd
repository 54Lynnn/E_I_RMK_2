extends Button

signal skill_upgraded(skill_id)

@export var skill_id: String = ""
@export var skill_name: String = ""
@export var skill_description: String = ""
@export var texture_path: String = ""
@export var max_level: int = 10
@export var prereq_skill: String = ""

enum Element { BASIC, EARTH, AIR, FIRE, WATER }
@export var element: Element = Element.BASIC

var current_level: int = 0:
	set(value):
		current_level = value
		update_display()

@onready var icon_texture := $VBoxContainer/Icon
@onready var level_label := $VBoxContainer/LevelLabel
@onready var element_bar := $ElementBar
@onready var border := $Border

const ELEMENT_COLORS := {
	Element.BASIC: Color("#C084FC"),
	Element.EARTH: Color("#A08420"),
	Element.AIR: Color("#C8C8C8"),
	Element.FIRE: Color("#D94A2A"),
	Element.WATER: Color("#3B7FFF")
}

const ELEMENT_NAMES := {
	Element.BASIC: "Basic",
	Element.EARTH: "Earth",
	Element.AIR: "Air",
	Element.FIRE: "Fire",
	Element.WATER: "Water"
}

func _ready():
	pressed.connect(_on_pressed)
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		icon_texture.texture = load(texture_path)
	update_display()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if element_bar:
		element_bar.color = ELEMENT_COLORS.get(element, Color("#9370DB"))

func update_display():
	if level_label:
		level_label.text = str(current_level) + "/" + str(max_level)
	if current_level >= max_level:
		disabled = true
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_pressed():
	if Global.skill_points > 0 and current_level < max_level:
		Global.skill_points -= 1
		current_level += 1
		Global.skill_levels[skill_id] = current_level
		Global.skill_level_changed.emit(skill_id, current_level)
		skill_upgraded.emit(skill_id)
		update_display()

func _on_mouse_entered():
	if not skill_description.is_empty():
		show_tooltip()

func _on_mouse_exited():
	hide_tooltip()

func show_tooltip():
	var element_name = ELEMENT_NAMES.get(element, "Basic")
	var tooltip = Label.new()
	tooltip.name = "Tooltip"
	tooltip.text = "[ " + skill_name + " ]\n" + skill_description + "\n[ " + element_name + " ]  Level: " + str(current_level) + "/" + str(max_level)
	tooltip.position = Vector2(0, -70)
	add_child(tooltip)

func hide_tooltip():
	var tooltip = get_node_or_null("Tooltip")
	if tooltip:
		tooltip.queue_free()
