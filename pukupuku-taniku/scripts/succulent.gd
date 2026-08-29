class_name Succulent
extends Node3D

signal harvested(plant: Succulent)
signal jellied(plant: Succulent)

const SPRITES := {
	"laui": "res://assets/plants/sprite-laui.png",
	"gold_laui": "res://assets/plants/sprite-golden-laui.png",
	"colorata": "res://assets/plants/sprite-colorata.png",
	"affinis": "res://assets/plants/sprite-affinis.png",
	"purpusorum": "res://assets/plants/sprite-affinis.png",
	"lutea": "res://assets/plants/sprite-lutea.png",
	"juliana": "res://assets/plants/sprite-lutea.png",
	"kannte": "res://assets/plants/sprite-kante.png",
	"shaviana": "res://assets/plants/sprite-kante.png",
	"pinwheel": "res://assets/plants/sprite-kante.png",
	"gold_kannte": "res://assets/plants/sprite-golden-laui.png"
}

var data: Dictionary
var age := 0.0
var diameter_cm := 1.6
var growth_rate := 1.0
var state := "growing"
var original_pos := Vector3.ZERO
var target_offset := Vector3.ZERO
var rng := RandomNumberGenerator.new()
var label: Label
var visual_scale := 0.38
var plant_sprite: Sprite3D
var contact_shadow: MeshInstance3D

func setup(species: Dictionary, seed_value: int, screen_label: Label, _danger: Label) -> void:
	data = species
	rng.seed = seed_value
	label = screen_label
	growth_rate = float(data.base_growth_rate)
	_build_contact_shadow()
	plant_sprite = Sprite3D.new()
	var variant := str(data.get("visual_variant", "laui"))
	plant_sprite.texture = load(str(SPRITES.get(variant, SPRITES.laui)))
	plant_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plant_sprite.no_depth_test = false
	plant_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	plant_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	plant_sprite.position.y = .18
	plant_sprite.pixel_size = 1.42 / maxf(1.0, float(plant_sprite.texture.get_width()))
	add_child(plant_sprite)
	_update_visual(0.0)

func _build_contact_shadow() -> void:
	contact_shadow = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.55, .78)
	contact_shadow.mesh = quad
	contact_shadow.rotation_degrees.x = -90.0
	contact_shadow.position.y = .025
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
void fragment(){vec2 p=(UV-vec2(.5))*2.0;float a=smoothstep(1.0,.08,dot(p,p));ALBEDO=vec3(.035,.018,.012);ALPHA=a*.30;}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	contact_shadow.material_override = material
	add_child(contact_shadow)

func simulate(delta: float) -> void:
	if state != "growing": return
	age += delta
	var spread := age / 16.0
	diameter_cm = 1.6 + spread * 19.0
	visual_scale = .26 + spread * 2.55
	_update_visual(delta)
	position += (original_pos + target_offset - position) * min(delta * 1.8, 1.0)

func _update_visual(delta: float) -> void:
	if plant_sprite == null: return
	var target: Vector3 = Vector3.ONE * visual_scale
	var response: float = 1.0 if delta <= 0.0 else min(delta * 4.5, 1.0)
	plant_sprite.scale = plant_sprite.scale.lerp(target, response)
	plant_sprite.rotation.z = sin(age * 1.35 + float(rng.seed % 17)) * .006
	contact_shadow.scale = Vector3(visual_scale * 1.04, visual_scale * 1.04, visual_scale * .72)

func get_risk_percent() -> float: return 0.0

func harvest() -> void:
	if state != "growing": return
	state = "harvested"
	harvested.emit(self)

func jelly() -> void:
	if state != "growing": return
	state = "jelly"
	jellied.emit(self)

func hit_radius() -> float: return max(.42, visual_scale * .72)
