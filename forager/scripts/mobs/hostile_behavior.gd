extends MobBehavior
class_name HostileBehavior

var _chasing := false
var _cooldown := 0.0

func physics_update(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	var player = mob.get_player()
	if player == null:
		wander(delta)
		return

	var dist = mob.global_position.distance_to(player.global_position)
	if _chasing and dist > data.lose_radius:
		_chasing = false
	elif not _chasing and dist <= data.detection_radius:
		_chasing = true

	if not _chasing:
		wander(delta)
		return

	if dist <= data.attack_range:
		mob.velocity = Vector2.ZERO
		if _cooldown <= 0.0:
			PlayerVitals.damage(data.attack_damage, true)
			_cooldown = data.attack_cooldown
	else:
		mob.velocity = (player.global_position - mob.global_position).normalized() * data.chase_speed

func on_hit(_source: Node2D) -> void:
	_chasing = true
