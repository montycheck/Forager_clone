extends RefCounted
class_name MobBehavior

var mob: Mob
var data: MobData

var _wander_dir := Vector2.ZERO
var _wander_timer := 0.0
var _moving := false

func setup(p_mob: Mob):
	mob = p_mob
	data = p_mob.data
	_wander_timer = randf_range(0.0, data.wander_pause_max)
	
func physics_update(delta: float):
	wander(delta)
	
func on_hit(_source: Node2D):
	pass
	
func wander(delta: float):
	_wander_timer -= delta
	if _moving and mob.is_on_wall():
		_wander_dir = Vector2.from_angle(randf() * TAU)
	if _wander_timer <= 0.0:
		_moving = not _moving
		if _moving:
			_wander_dir = Vector2.from_angle(randf() * TAU)
			_wander_timer = randf_range(data.wander_move_min, data.wander_move_max)
		else:
			_wander_timer = randf_range(data.wander_pause_min, data.wander_pause_max)
	mob.velocity = _wander_dir * data.move_speed if _moving else Vector2.ZERO
