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
var jelly_load := 0.0
var jelly_threshold := 1.0
var sway_phase := 0.0

func setup(species: Dictionary, seed_value: int, screen_label: Label, _danger: Label) -> void:
	data = species
	rng.seed = seed_value
	sway_phase = rng.randf_range(0.0, TAU)
	# Exponential hidden threshold keeps every plant unpredictable. A very small
	# resilience tail permits exceptional 30–78+ second specimens without a cap.
	jelly_threshold = -log(maxf(rng.randf(), 0.000001))
	var resilience_roll := rng.randf()
	if resilience_roll < 0.0005:
		jelly_threshold *= rng.randf_range(12.0, 30.0)
	elif resilience_roll < 0.006:
		jelly_threshold *= rng.randf_range(3.0, 10.0)
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
	plant_sprite.position.y = .26
	# Lift the artwork inside its quad so scaling grows upward from the soil,
	# preventing the lower leaves from sinking behind the soil or pot rim.
	plant_sprite.offset.y = -float(plant_sprite.texture.get_height()) * .18
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
	var spread := age * growth_rate / 16.0
	diameter_cm = 1.6 + spread * 19.0
	visual_scale = .26 + spread * 2.55
	_update_visual(delta)
	# Risk is invisible while healthy and rises continuously with size. There is
	# no maximum lifetime: only the accumulated hidden threshold decides jelly.
	var size_factor := maxf(0.0, (diameter_cm - 1.6) / 9.0)
	var risk_curve := float(data.get("jelly_risk_curve", 1.0))
	jelly_load += delta * (0.045 + 0.022 * size_factor + 0.018 * size_factor * size_factor) * risk_curve
	if jelly_load >= jelly_threshold:
		jelly()

func _update_visual(delta: float) -> void:
	if plant_sprite == null: return
	var target: Vector3 = Vector3.ONE * visual_scale
	var response: float = 1.0 if delta <= 0.0 else min(delta * 4.5, 1.0)
	plant_sprite.scale = plant_sprite.scale.lerp(target, response)
	# Anchor the lower edge near the soil as the centered billboard grows.
	# Only the artwork rises; the plant node itself never changes position.
	plant_sprite.position.y = .10 + visual_scale * .62
	plant_sprite.rotation.z = sin(age * .72 + sway_phase) * .0045
	plant_sprite.position.x = sin(age * .58 + sway_phase * .73) * .007
	contact_shadow.scale = Vector3(visual_scale * 1.04, visual_scale * 1.04, visual_scale * .72)

func get_risk_percent() -> float: return 0.0

func harvest() -> void:
	if state != "growing": return
	state = "harvested"
	harvested.emit(self)

func jelly() -> void:
	if state != "growing": return
	state = "jelly"
	plant_sprite.modulate = Color(0.78, 0.90, 0.86, 0.72)
	jellied.emit(self)

func hit_radius() -> float: return max(.42, visual_scale * .72)
