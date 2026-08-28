class_name Succulent
extends Node3D

signal harvested(plant: Succulent)
signal jellied(plant: Succulent)

const SPRITES := {
	"laui": "res://assets/plants/laui.png",
	"gold_laui": "res://assets/plants/golden_laui.png",
	"affinis": "res://assets/plants/affinis.png"
}

var data: Dictionary
var age := 0.0
var diameter_cm := 1.6
var growth_rate := 1.0
var risk_bias := 1.0
var state := "growing"
var original_pos := Vector3.ZERO
var target_offset := Vector3.ZERO
var rng := RandomNumberGenerator.new()
var label: Label
var max_life_hint := 7.0
var visual_scale := 0.18
var plant_sprite: Sprite3D
var contact_shadow: MeshInstance3D
var golden_particles: GPUParticles3D
var style := "laui"

func setup(species: Dictionary, seed_value: int, screen_label: Label, _danger: Label) -> void:
	data = species
	rng.seed = seed_value
	label = screen_label
	growth_rate = float(data.base_growth_rate) * rng.randf_range(0.84, 1.18)
	risk_bias = float(data.jelly_risk_curve) * rng.randf_range(0.78, 1.22)
	style = str(data.visual_variant)
	max_life_hint = _sample_life_hint()
	_build_contact_shadow()
	_build_sprite()
	if style == "gold_laui": _build_golden_aura()

func _sample_life_hint() -> float:
	var p := rng.randf()
	if p < .002: return rng.randf_range(55.0, 110.0)
	if p < .012: return rng.randf_range(25.0, 55.0)
	if p < .055: return rng.randf_range(14.0, 28.0)
	return clamp(rng.randfn(7.2, 3.1), 2.8, 18.0)

func _build_sprite() -> void:
	plant_sprite = Sprite3D.new()
	plant_sprite.texture = load(SPRITES.get(style, SPRITES.laui))
	plant_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plant_sprite.pixel_size = 0.00235
	plant_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	plant_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	plant_sprite.shaded = false
	plant_sprite.position.y = 0.24
	plant_sprite.render_priority = 1 if style == "gold_laui" else 0
	add_child(plant_sprite)

func _build_contact_shadow() -> void:
	contact_shadow = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.55, 1.70)
	quad.orientation = PlaneMesh.FACE_Y
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;
void fragment(){vec2 p=(UV-vec2(0.5))*2.0;float fade=1.0-smoothstep(0.18,1.0,dot(p,p));ALBEDO=vec3(0.035,0.012,0.006);ALPHA=fade*0.28;}"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	quad.material = mat
	contact_shadow.mesh = quad
	contact_shadow.position.y = -0.025
	add_child(contact_shadow)

func _build_golden_aura() -> void:
	golden_particles = GPUParticles3D.new()
	golden_particles.amount = 12
	golden_particles.lifetime = 2.4
	golden_particles.randomness = .9
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = .70
	process.initial_velocity_min = .02
	process.initial_velocity_max = .07
	process.gravity = Vector3(0, .045, 0)
	process.scale_min = .018
	process.scale_max = .045
	golden_particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(.065, .065)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, .86, .30, .72)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = mat
	golden_particles.draw_pass_1 = quad
	golden_particles.position.y = .25
	add_child(golden_particles)

func simulate(delta: float) -> void:
	if state != "growing": return
	age += delta
	diameter_cm += delta * growth_rate * (1.55 + diameter_cm * .055)
	var pulse := 1.0 + sin(age * 1.75 + float(rng.seed % 23)) * .008
	visual_scale = (.14 + pow(diameter_cm / 12.0, .78) * .74) * pulse
	scale = Vector3.ONE * visual_scale
	plant_sprite.scale = Vector3(1.0 + sin(age * .72) * .010, 1.0 + sin(age * .72 + 1.2) * .008, 1.0)
	contact_shadow.scale = Vector3(1.0 + min(age / 55.0, .10), 1.0, 1.0 + min(age / 55.0, .10))
	position += (original_pos + target_offset - position) * min(delta * 1.8, 1.0)
	if age > 1.8 and rng.randf() < _jelly_probability(delta): jelly()

func _jelly_probability(delta: float) -> float:
	var maturity: float = max(0.0, age - 2.0)
	var life_pressure := pow(maturity / max_life_hint, 2.25)
	var size_pressure := pow(max(0.0, diameter_cm - 5.0) / 28.0, 1.75)
	return clamp((life_pressure * .34 + size_pressure * .13) * risk_bias * delta, 0.0, .34)

func get_risk_percent() -> float:
	var maturity: float = max(0.0, age - 1.5)
	return clamp((pow(maturity / max_life_hint, 1.7) * 72.0 + pow(max(0, diameter_cm - 7.0) / 30.0, 1.4) * 32.0) * risk_bias, 2.0, 99.0)

func harvest() -> void:
	if state != "growing": return
	state = "harvested"
	harvested.emit(self)

func jelly() -> void:
	if state != "growing": return
	state = "jelly"
	plant_sprite.modulate = Color(.72, .82, .78, .76)
	plant_sprite.position.y = .13
	jellied.emit(self)

func hit_radius() -> float:
	return max(.24, visual_scale * 1.05)
