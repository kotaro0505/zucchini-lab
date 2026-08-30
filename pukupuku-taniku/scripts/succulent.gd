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
const GROWTH_CM_PER_SECOND := 1.1875
const NORMAL_JELLY_CHANCE_PER_SECOND := .143

var visual_scale := 0.18
var plant_sprite: Sprite3D
var contact_shadow: MeshInstance3D
var is_special := false
var jelly_checks_enabled := true
var sway_phase := 0.0

func setup(species: Dictionary, seed_value: int, screen_label: Label, _danger: Label) -> void:
	data = species
	rng.seed = seed_value
	sway_phase = rng.randf_range(0.0, TAU)
	is_special = rng.randf() < 0.10
	label = screen_label
	# Species rarity and the independent special roll never change growth speed.
	growth_rate = 1.0
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
	if is_special: _play_special_birth_glow()

func _play_special_birth_glow() -> void:
	# A brief warm bloom announces the 10% roll without leaving a permanent mark.
	plant_sprite.modulate = Color(1.38, 1.18, .68, 1.0)
	var glow := OmniLight3D.new()
	glow.light_color = Color("#ffd56a")
	glow.light_energy = 2.0
	glow.omni_range = 3.2
	glow.position = Vector3(0, .75, .08)
	add_child(glow)
	var tw := create_tween().set_parallel()
	tw.tween_property(plant_sprite, "modulate", Color.WHITE, .9).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(glow, "light_energy", 0.0, .9).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(glow.queue_free)

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
	diameter_cm = 1.6 + age * GROWTH_CM_PER_SECOND * growth_rate
	# One physical-looking scale mapping for all sizes, with no clamp or cap.
	# 30cm is now a moderate plant; 60–70cm is when it dominates the view.
	visual_scale = .18 + (diameter_cm - 1.6) * .058
	_update_visual(delta)
	if jelly_checks_enabled:
		# Convert the specified one-second chance to a continuous hazard, then back
		# to this frame's chance. This is FPS independent and never preselects a
		# lifetime or final size.
		var rate := -log(1.0-NORMAL_JELLY_CHANCE_PER_SECOND)
		if is_special:rate*=.85
		var jelly_probability := 1.0-exp(-rate*delta)
		if rng.randf() < jelly_probability: jelly()

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
