extends Node

enum Rarity {
	COMMON,
	UNCOMMON,
	UNIQUE,
	RARE,
	EXCEPTIONAL
}

const BASE_DROP_CHANCE := 0.10

var loot_table := {
	Rarity.COMMON: {
		"weight": 40,
		"items": [
			0,
			1,
		]
	},
	Rarity.UNCOMMON: {
		"weight": 30,
		"items": [
			2,
			3,
		]
	},
	Rarity.UNIQUE: {
		"weight": 15,
		"items": [
			4,
			5,
		]
	},
	Rarity.RARE: {
		"weight": 10,
		"items": [
			6,
			7,
			8,
		]
	},
	Rarity.EXCEPTIONAL: {
		"weight": 5,
		"items": [
			9,
			10,
			11,
		]
	}
}

func get_drop_chance() -> float:
	return BASE_DROP_CHANCE * Global.drop_rate_multiplier

func try_drop(position: Vector2, parent: Node) -> bool:
	if randf() > get_drop_chance():
		return false
	
	var item_type = roll_item()
	spawn_item(item_type, position, parent)
	return true

func roll_item() -> int:
	var total_weight := 0
	for rarity in loot_table.values():
		total_weight += rarity.weight
	
	var roll := randi() % total_weight
	var current_weight := 0
	
	for rarity_data in loot_table.values():
		current_weight += rarity_data.weight
		if roll < current_weight:
			var items: Array = rarity_data.items
			return items[randi() % items.size()]
	
	return 0

func spawn_item(item_type: int, position: Vector2, parent: Node):
	var item = preload("res://Scenes/PickupItem.tscn").instantiate()
	item.item_type = item_type
	item.global_position = position
	parent.add_child(item)
