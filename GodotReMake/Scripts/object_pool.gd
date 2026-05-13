extends Node

var _pools := {}

var _default_pool_sizes := {
	"res://Scenes/Projectile.tscn": 20,
	"res://Scenes/MagicMissile.tscn": 15,
	"res://Scenes/NovaProj.tscn": 10,
	"res://Scenes/ChainLightningProj.tscn": 10,
	"res://Scenes/Explosion.tscn": 20,
	"res://Scenes/FireWalk.tscn": 5,
	"res://Scenes/PoisonCloud.tscn": 5,
	"res://Scenes/Meteor.tscn": 5,
	"res://Scenes/ArmageddonZone.tscn": 5,
	"res://Scenes/MonsterArrow.tscn": 15,
}

func _ready():
	for scene_path in _default_pool_sizes:
		_warm_pool(scene_path, _default_pool_sizes[scene_path])

func _warm_pool(scene_path: String, count: int):
	var scene = load(scene_path)
	if scene == null:
		return
	_pools[scene_path] = []
	for i in range(count):
		var obj = scene.instantiate()
		obj.visible = false
		obj.set_process(false)
		obj.set_physics_process(false)
		obj.process_mode = PROCESS_MODE_DISABLED
		add_child(obj)
		_pools[scene_path].append(obj)

func get_object(scene: PackedScene) -> Node:
	var scene_path = scene.resource_path
	if not _pools.has(scene_path):
		_pools[scene_path] = []
	if _pools[scene_path].size() > 0:
		var obj = _pools[scene_path].pop_back()
		remove_child(obj)
		obj.visible = true
		obj.set_process(true)
		obj.set_physics_process(true)
		obj.process_mode = PROCESS_MODE_INHERIT
		if obj.has_method("reset_for_pool"):
			obj.reset_for_pool()
		return obj
	return scene.instantiate()

func return_to_pool(obj: Node):
	var scene_path = obj.scene_file_path
	if scene_path.is_empty() or not _default_pool_sizes.has(scene_path):
		obj.queue_free()
		return
	if not _pools.has(scene_path):
		_pools[scene_path] = []
	_pools[scene_path].append(obj)
	if obj.has_method("reset_for_pool"):
		obj.reset_for_pool()
	obj.visible = false
	obj.set_process(false)
	obj.set_physics_process(false)
	obj.process_mode = PROCESS_MODE_DISABLED
	add_child(obj)
