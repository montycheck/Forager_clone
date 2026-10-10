extends Resource
class_name MobData

@export var id: String = ""
@export var display_name: String = ""
@export var sprite_texture: Texture2D
@export var behavior_script: GDScript
@export var max_health: int = 10
@export var move_speed: float = 40.0
@export var xp_reward: int = 5
@export var blocks_player: bool = false   # le mob bloque-t-il physiquement le joueur ?
@export var knockback_force: float = 150.0   # 0 = pas de recul
@export var spawn_count: int = 10
@export var respawn_time: float = 60.0   # secondes avant réapparition (0 = pas de respawn)
@export var drops: Array[DropEntry] = []

@export_group("Errance")
@export var wander_move_min: float = 0.8
@export var wander_move_max: float = 2.0
@export var wander_pause_min: float = 1.0
@export var wander_pause_max: float = 3.0

@export_group("Hostile")
@export var detection_radius: float = 120.0
@export var lose_radius: float = 220.0
@export var chase_speed: float = 70.0
@export var attack_range: float = 24.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0

@export_group("Craintif")
@export var flee_speed: float = 90.0
@export var flee_duration: float = 2.5
