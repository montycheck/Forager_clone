extends MobBehavior
class_name SkittishBehavior

var _flee_timer := 0.0
var _flee_dir := Vector2.ZERO

func physics_update(delta: float) -> void:
	if _flee_timer > 0.0:
		_flee_timer -= delta
		if mob.is_on_wall():
			_flee_dir = Vector2.from_angle(randf() * TAU)
		mob.velocity = _flee_dir * data.flee_speed
		return
	wander(delta)

func on_hit(source: Node2D) -> void:
	_flee_timer = data.flee_duration
	var away = mob.global_position - source.global_position if source != null else Vector2.ZERO
	_flee_dir = away.normalized() if away != Vector2.ZERO else Vector2.from_angle(randf() * TAU)
