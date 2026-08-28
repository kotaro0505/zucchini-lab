class_name Succulent
extends Node3D

signal harvested(plant: Succulent)
signal jellied(plant: Succulent)

var data: Dictionary
var age := 0.0
var diameter_cm := 1.6
var growth_rate := 1.0
var risk_bias := 1.0
var state := "growing"
var leaf_nodes: Array[MeshInstance3D] = []
var original_pos := Vector3.ZERO
var target_offset := Vector3.ZERO
var rng := RandomNumberGenerator.new()
var label: Label
var danger_badge: Label
var golden_particles: GPUParticles3D
var leaf_mesh: ArrayMesh
var base_color := Color("#b7cda8")
var tip_color := Color("#eb8f9b")
var style := "broad_blue"
var max_life_hint := 7.0
var visual_scale := 0.18
var wobble := 0.0

func setup(species: Dictionary, seed_value: int, screen_label: Label, danger: Label) -> void:
	data = species
	rng.seed = seed_value
	label = screen_label
	danger_badge = danger
	growth_rate = float(data.base_growth_rate) * rng.randf_range(0.84, 1.18)
	risk_bias = float(data.jelly_risk_curve) * rng.randf_range(0.78, 1.22)
	style = str(data.visual_variant)
	base_color = Color(str(data.colors[0]))
	tip_color = Color(str(data.colors[1]))
	max_life_hint = _sample_life_hint()
	leaf_mesh = _create_leaf_mesh(style)
	_build_rosette()
	if style.begins_with("gold"):
		_build_golden_aura()

func _sample_life_hint() -> float:
	var p := rng.randf()
	if p < 0.002: return rng.randf_range(55.0, 110.0)
	if p < 0.012: return rng.randf_range(25.0, 55.0)
	if p < 0.055: return rng.randf_range(14.0, 28.0)
	return clamp(rng.randfn(7.2, 3.1), 2.8, 18.0)

func _create_leaf_mesh(variant: String) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length := 1.0
	var width := 0.48
	var thickness := 0.16
	if "round" in variant: width = 0.62; length = 0.88; thickness = 0.21
	if "slender" in variant: width = 0.30; length = 1.12; thickness = 0.13
	if "compact" in variant: width = 0.52; length = 0.76; thickness = 0.19
	if "sharp" in variant: width = 0.35; length = 1.04; thickness = 0.14
	var seg_l := 9
	var seg_w := 6
	for side in [-1.0, 1.0]:
		for i in range(seg_l):
			for j in range(seg_w):
				var a := _leaf_point(float(i)/seg_l, float(j)/seg_w, side, length, width, thickness)
				var b := _leaf_point(float(i+1)/seg_l, float(j)/seg_w, side, length, width, thickness)
				var c := _leaf_point(float(i+1)/seg_l, float(j+1)/seg_w, side, length, width, thickness)
				var d := _leaf_point(float(i)/seg_l, float(j+1)/seg_w, side, length, width, thickness)
				if side > 0.0: _tri(st, a,b,c); _tri(st,a,c,d)
				else: _tri(st,a,c,b); _tri(st,a,d,c)
	# sealed curved rim
	for edge_j in [0, seg_w]:
		for i in range(seg_l):
			var u0 := float(i)/seg_l; var u1 := float(i+1)/seg_l; var v := float(edge_j)/seg_w
			var t0 := _leaf_point(u0,v,1,length,width,thickness); var t1 := _leaf_point(u1,v,1,length,width,thickness)
			var b0 := _leaf_point(u0,v,-1,length,width,thickness); var b1 := _leaf_point(u1,v,-1,length,width,thickness)
			_tri(st,t0,b0,b1); _tri(st,t0,b1,t1)
	st.generate_normals()
	return st.commit()

func _leaf_point(u: float, v: float, side: float, length: float, width: float, thickness: float) -> Vector3:
	var taper := sin(PI * pow(u, 0.88))
	var across := (v - 0.5) * 2.0
	var x := across * width * taper * (0.88 + 0.12 * sin(PI*u))
	var z := u * length
	var cup := (1.0 - across*across) * thickness * sin(PI*u) * side
	var arch := 0.17 * sin(PI*u) - 0.09 * u*u
	var ridge: float = 0.055 * (1.0 - abs(across)) * sin(PI*u)
	return Vector3(x, arch + cup + ridge, z)

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for p in [a,b,c]:
		var u: float = clamp(p.z,0.0,1.0)
		st.set_uv(Vector2((p.x+0.7)/1.4,u))
		st.add_vertex(p)

func _build_rosette() -> void:
	var rings := [12, 10, 8, 5]
	if "compact" in style: rings = [11,9,7,5]
	if "slender" in style: rings = [14,11,8,5]
	for ring_i in range(rings.size()):
		var count: int = rings[ring_i]
		var ring_t := float(ring_i) / float(rings.size()-1)
		for j in range(count):
			var leaf := MeshInstance3D.new()
			leaf.mesh = leaf_mesh
			var mat := StandardMaterial3D.new()
			var mix_t := rng.randf_range(0.0, 0.16) + ring_t*0.05
			mat.albedo_color = base_color.darkened(0.34).lightened(mix_t)
			mat.roughness = 0.73 if not style.begins_with("gold") else 0.38
			mat.metallic = 0.0 if not style.begins_with("gold") else 0.16
			# Compatibility/Web: powdery softness comes from roughness and broad curves.
			# SSS is intentionally avoided because GLES3 ignores it and can over-brighten.
			leaf.material_override = mat
			leaf.rotation.y = TAU * float(j)/count + ring_i*0.29 + rng.randf_range(-0.055,0.055)
			var radial: float = lerp(0.36, 0.035, ring_t)
			leaf.position = Vector3(sin(leaf.rotation.y)*radial, ring_t*0.09, cos(leaf.rotation.y)*radial)
			leaf.rotation.x = lerp(-0.22, -0.98, ring_t) + rng.randf_range(-0.04,0.04)
			leaf.scale = Vector3.ONE * lerp(1.0,0.48,ring_t) * rng.randf_range(0.95,1.06)
			leaf.set_meta("ring", ring_t)
			leaf.set_meta("phase", rng.randf_range(0.0,TAU))
			add_child(leaf)
			leaf_nodes.append(leaf)
	# colored tips as tiny soft meshes, not flat decals
	for i in range(0, leaf_nodes.size(), 2):
		var leaf := leaf_nodes[i]
		var tip := MeshInstance3D.new()
		var sphere := SphereMesh.new(); sphere.radius = 0.08; sphere.height = 0.13; sphere.radial_segments = 8; sphere.rings = 4
		tip.mesh = sphere
		var tm := StandardMaterial3D.new(); tm.albedo_color = tip_color.darkened(0.12); tm.roughness = 0.64
		tip.material_override = tm
		tip.position = Vector3(0.0,0.01,0.95)
		tip.scale = Vector3(0.72,0.32,0.42)
		leaf.add_child(tip)

func _build_golden_aura() -> void:
	var light := OmniLight3D.new()
	light.light_color = Color("#ffd875")
	light.light_energy = 0.42
	light.omni_range = 3.1
	light.shadow_enabled = false
	add_child(light)
	golden_particles = GPUParticles3D.new()
	golden_particles.amount = 12
	golden_particles.lifetime = 2.5
	golden_particles.randomness = 0.7
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.75
	process.initial_velocity_min = 0.05; process.initial_velocity_max = 0.14
	process.gravity = Vector3(0,0.12,0)
	process.scale_min = 0.025; process.scale_max = 0.055
	golden_particles.process_material = process
	var quad := QuadMesh.new(); quad.size = Vector2(0.08,0.08)
	var sm := StandardMaterial3D.new(); sm.albedo_color=Color("#fff0a3"); sm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; sm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = sm
	golden_particles.draw_pass_1 = quad
	add_child(golden_particles)

func simulate(delta: float) -> void:
	if state != "growing": return
	age += delta
	var pulse := 1.0 + sin(age*2.0 + rng.seed%23)*0.018
	diameter_cm += delta * growth_rate * (1.55 + diameter_cm*0.055)
	visual_scale = (0.14 + pow(diameter_cm/12.0,0.78)*0.74) * pulse
	for leaf in leaf_nodes:
		var ring_t: float = leaf.get_meta("ring")
		var phase: float = leaf.get_meta("phase")
		var unfold: float = clamp(age / (2.5 + ring_t*2.0),0.0,1.0)
		leaf.rotation.x = lerp(-1.24 + ring_t*0.15, -0.16 - ring_t*0.73, ease(unfold,0.45)) + sin(age*1.7+phase)*0.018
		var plump: float = 0.78 + unfold*0.24 + min(age/35.0,0.16)
		var base_s: float = lerp(1.0,0.48,ring_t)
		leaf.scale = Vector3(plump, 0.82+unfold*0.22, 0.9+unfold*0.12) * base_s
	scale = Vector3.ONE * visual_scale
	position += (original_pos + target_offset - position) * min(delta*1.8,1.0)
	var danger := get_risk_percent()
	if danger > 64.0:
		wobble += delta
		rotation.z = sin(wobble*13.0)*0.018*inverse_lerp(64,100,danger)
		if danger_badge: danger_badge.visible = true
	if age > 1.8 and rng.randf() < _jelly_probability(delta):
		jelly()

func _jelly_probability(delta: float) -> float:
	var maturity: float = max(0.0, age - 2.0)
	var life_pressure := pow(maturity/max_life_hint, 2.25)
	var size_pressure := pow(max(0.0,diameter_cm-5.0)/28.0,1.75)
	return clamp((life_pressure*0.34 + size_pressure*0.13) * risk_bias * delta, 0.0, 0.34)

func get_risk_percent() -> float:
	var maturity: float = max(0.0,age-1.5)
	return clamp((pow(maturity/max_life_hint,1.7)*72.0 + pow(max(0,diameter_cm-7.0)/30.0,1.4)*32.0)*risk_bias,2.0,99.0)

func harvest() -> void:
	if state != "growing": return
	state = "harvested"
	emit_signal("harvested",self)

func jelly() -> void:
	if state != "growing": return
	state = "jelly"
	for leaf in leaf_nodes:
		var mat := leaf.material_override as StandardMaterial3D
		mat = mat.duplicate()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = mat.albedo_color.darkened(0.15); mat.albedo_color.a = 0.78
		mat.roughness = 0.18
		leaf.material_override = mat
	emit_signal("jellied",self)

func hit_radius() -> float:
	return max(0.24, visual_scale*0.95)
