class_name RelicData
extends Resource

enum Rarity { COMMON, UNCOMMON, UNIQUE, RARE, EXCEPTIONAL }

@export var id: String
@export var relic_name: String
@export var description: String
@export var rarity: Rarity
@export var icon_path: String
