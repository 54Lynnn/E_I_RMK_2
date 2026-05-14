extends Node

var sound_files: Dictionary = {}
var audio_players: Array = []

func _ready():
	_load_sound_list()
	_precache_players()

func _load_sound_list():
	var sound_names: Dictionary = {
		0: "HeroDeathBell",
		1: "HeroDeath",
		2: "HeroHit",
		3: "HeroLevelUp",
		4: "HeroNeedHealth",
		5: "HeroNeedMana",
		6: "ItemExperience",
		7: "IconButtonClick",
		8: "MenuButtonClick",
		9: "MenuRoll",
		10: "Music",
		11: "EffectBlood",
		12: "EffectIce",
		13: "EffectSpawn",
		14: "ArcherAttack",
		15: "ArcherDeath",
		16: "BearAttack",
		17: "BearDeath",
		18: "BossAttack",
		19: "BossDeath",
		20: "DemonAttack",
		21: "DemonDeath",
		22: "RigAttack",
		23: "RigDeath",
		24: "SpiderAttack",
		25: "SpiderDeath",
		26: "ReaperAttack",
		27: "ReaperDeath",
		28: "FireballCast",
		29: "FireballExplosion",
		30: "MissileCast",
		31: "MissileHit",
		32: "LightningCast",
		33: "LightningStrike",
		34: "NovaCast",
		35: "NovaExplosion",
		36: "MeteorPentagram",
		37: "MeteorFall",
		38: "MeteorExplosion",
		39: "ArmageddonCast",
		40: "PoisonCloud",
		41: "SpearCast",
		42: "SpearTarget",
		43: "HolyLight",
		44: "Heal",
		45: "Prayer",
		46: "Slow",
		47: "Sacrifice",
		48: "Teleport",
		49: "Telekenesis",
		50: "DarkRitualCast",
		51: "DarkRitualSouls",
		52: "StoneToDust",
		53: "WrathOfGod",
		54: "FireWalk",
		55: "Fortuna",
		56: "BallLightningCast",
		57: "BallLightningStrike",
		58: "ItemHealth",
		59: "ItemMana",
		60: "ItemRejuvenation",
		61: "ItemSpeed",
		62: "ItemQuadDamage",
		63: "ItemPhysicResist",
		64: "ItemMagicResist",
		65: "ItemImmunity",
		66: "ItemFreeSpells",
		67: "ItemSkillPoint",
		68: "ItemAttributePoint",
	}

	for idx in range(69):
		var path: String = "res://Art/Sounds/sound_%d.ogg" % idx
		var name: String = sound_names.get(idx, "sound_%d" % idx)
		sound_files[name.to_lower()] = path

func _precache_players(count: int = 16):
	for i in range(count):
		var player := AudioStreamPlayer2D.new()
		player.name = "AudioPlayer_%d" % i
		add_child(player)
		audio_players.append(player)

func play_sound(sound_name: String, position: Vector2 = Vector2.ZERO):
	var key = sound_name.to_lower()
	if not sound_files.has(key):
		push_warning("SoundManager: Unknown sound '%s'" % sound_name)
		return

	var player = _get_free_player()
	if player == null:
		return

	var path = sound_files[key]
	var stream = load(path)
	if stream == null:
		return

	player.stream = stream
	player.global_position = position
	player.play()

func play_sound_global(sound_name: String):
	var key = sound_name.to_lower()
	if not sound_files.has(key):
		push_warning("SoundManager: Unknown sound '%s'" % sound_name)
		return

	var path = sound_files[key]
	var stream = load(path)
	if stream == null:
		return

	var player = _get_free_player()
	if player == null:
		return

	player.stream = stream
	player.global_position = Vector2.ZERO
	player.play()

func _get_free_player():
	for player in audio_players:
		if not player.playing:
			return player
	return null
