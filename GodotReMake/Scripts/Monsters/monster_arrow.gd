extends Area2D

@export var speed := 300.0
@export var damage := 6.0
@export var lifetime := 3.0
var direction := Vector2.RIGHT

var homing_target: Node2D = null
var homing_strength := 0.0

var _lifetime_timer := 0.0

func _ready():
	body_entered.connect(_on_body_entered)

func reset_for_pool():
	speed = 300.0
	damage = 6.0
	lifetime = 3.0
	direction = Vector2.RIGHT
	homing_target = null
	homing_strength = 0.0
	_lifetime_timer = 0.0

func _return_to_pool():
	ObjectPool.return_to_pool(self)

func _process(delta):
	if homing_target and homing_strength > 0:
		var target_dir = global_position.direction_to(homing_target.global_position)
		var current_angle = direction.angle()
		var target_angle = target_dir.angle()
		var angle_diff = wrapf(target_angle - current_angle, -PI, PI)
		var max_turn = deg_to_rad(homing_strength) * delta
		angle_diff = clamp(angle_diff, -max_turn, max_turn)
		direction = direction.rotated(angle_diff)

	position += direction * speed * delta
	$Sprite2D.rotation = atan2(direction.y, direction.x)

	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		_return_to_pool()

func _on_body_entered(body: Node2D):
	if body.is_in_group("hero"):
		Global.take_damage(damage, false, null)
		_return_to_pool()
