extends Node
class_name HoverHighlight

const STRENGTH_IN_RANGE := 0.3
const STRENGTH_OUT_OF_RANGE := 0.0
const TINT := Color(1.0, 1.0, 1.0)

const SHADER_CODE := """
shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.3;
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	COLOR.rgb += tint * strength * COLOR.a;
}
"""

var _material := ShaderMaterial.new()
var _target: Node2D = null
var _target_sprite: Sprite2D = null
var _previous_material: Material = null

func _init() -> void:
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_material.shader = shader
	_material.set_shader_parameter("tint", Vector3(TINT.r, TINT.g, TINT.b))

func set_target(new_target: Node2D, in_range: bool) -> void:
	if new_target != _target:
		_clear()
		_target = new_target
		if new_target != null:
			var sprite := new_target.get_node_or_null("Sprite") as Sprite2D
			if sprite != null:
				_target_sprite = sprite
				_previous_material = sprite.material
				sprite.material = _material

	var strength := STRENGTH_IN_RANGE if in_range else STRENGTH_OUT_OF_RANGE
	_material.set_shader_parameter("strength", strength)

func _clear() -> void:
	if _target_sprite != null and is_instance_valid(_target_sprite):
		_target_sprite.material = _previous_material
	_target_sprite = null
	_previous_material = null
	_target = null
