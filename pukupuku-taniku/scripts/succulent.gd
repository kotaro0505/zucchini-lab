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
var base_color := Color("#799e83")
var tip_color := Color("#d96e7a")
var style := "colorata"
var profile: Dictionary
var max_life_hint := 7.0
var visual_scale := 0.18
var wobble := 0.0

func setup(species: Dictionary, seed_value: int, screen_label: Label, danger: Label) -> void:
	data = species; rng.seed = seed_value; label = screen_label; danger_badge = danger
	growth_rate = float(data.base_growth_rate) * rng.randf_range(0.84, 1.18)
	risk_bias = float(data.jelly_risk_curve) * rng.randf_range(0.78, 1.22)
	style = str(data.visual_variant)
	base_color = Color("#" + str(data.colors[0])); tip_color = Color("#" + str(data.colors[1]))
	profile = _profile_for(style); max_life_hint = _sample_life_hint()
	var mesh := _create_plump_leaf_mesh(); var material := _create_leaf_material()
	_build_rosette(mesh, material); _build_crown_bud()
	if style.begins_with("gold_"): _build_golden_aura()

func _profile_for(variant: String) -> Dictionary:
	var profiles := {
		"colorata":{"length":1.02,"width":.50,"thick":.23,"arch":.15,"tip_lift":.20,"point":1.45,"rings":[13,11,8,5],"open":.20,"inner":.98,"spiral":.20,"frill":0.0,"powder":.82},
		"lutea":{"length":.92,"width":.57,"thick":.25,"arch":.18,"tip_lift":.13,"point":.92,"rings":[12,10,8,5],"open":.17,"inner":.93,"spiral":.12,"frill":0.0,"powder":.68},
		"purpusorum":{"length":.89,"width":.39,"thick":.22,"arch":.11,"tip_lift":.27,"point":1.75,"rings":[11,9,7,5],"open":.32,"inner":1.10,"spiral":.08,"frill":0.0,"powder":.42},
		"shaviana":{"length":.94,"width":.58,"thick":.16,"arch":.20,"tip_lift":.10,"point":1.05,"rings":[14,12,9,6],"open":.12,"inner":.88,"spiral":.25,"frill":.12,"powder":.76},
		"pinwheel":{"length":1.10,"width":.35,"thick":.19,"arch":.17,"tip_lift":.22,"point":1.55,"rings":[15,12,9,5],"open":.10,"inner":.90,"spiral":.53,"frill":0.0,"powder":.64},
		"juliana":{"length":.80,"width":.49,"thick":.28,"arch":.21,"tip_lift":.18,"point":1.20,"rings":[12,10,7,5],"open":.28,"inner":1.03,"spiral":.31,"frill":0.0,"powder":.74},
		"affinis":{"length":1.0,"width":.34,"thick":.20,"arch":.10,"tip_lift":.30,"point":1.90,"rings":[12,10,8,5],"open":.34,"inner":1.15,"spiral":.16,"frill":0.0,"powder":.30},
		"laui":{"length":.82,"width":.68,"thick":.34,"arch":.24,"tip_lift":.10,"point":.72,"rings":[12,10,8,5],"open":.22,"inner":.92,"spiral":.18,"frill":0.0,"powder":.96},
		"kannte":{"length":1.22,"width":.57,"thick":.24,"arch":.17,"tip_lift":.19,"point":1.22,"rings":[14,12,9,5],"open":.04,"inner":.82,"spiral":.27,"frill":0.0,"powder":.90},
		"gold_laui":{"length":.84,"width":.68,"thick":.35,"arch":.25,"tip_lift":.10,"point":.70,"rings":[12,10,8,5],"open":.21,"inner":.92,"spiral":.18,"frill":0.0,"powder":.48},
		"gold_kannte":{"length":1.23,"width":.58,"thick":.25,"arch":.18,"tip_lift":.19,"point":1.20,"rings":[14,12,9,5],"open":.04,"inner":.82,"spiral":.27,"frill":0.0,"powder":.44}
	}
	return profiles.get(variant, profiles.colorata)

func _sample_life_hint() -> float:
	var p := rng.randf()
	if p < .002: return rng.randf_range(55.0,110.0)
	if p < .012: return rng.randf_range(25.0,55.0)
	if p < .055: return rng.randf_range(14.0,28.0)
	return clamp(rng.randfn(7.2,3.1),2.8,18.0)

func _create_leaf_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color.WHITE; mat.vertex_color_use_as_albedo = true
	mat.roughness = float(profile.powder); mat.metallic = .10 if style.begins_with("gold_") else 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX; mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func _create_plump_leaf_mesh() -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); st.set_smooth_group(0)
	var seg_l := 18; var seg_w := 12
	for side in [-1.0,1.0]:
		for i in range(seg_l):
			for j in range(seg_w):
				var u0:=float(i)/seg_l; var u1:=float(i+1)/seg_l; var v0:=float(j)/seg_w; var v1:=float(j+1)/seg_w
				var a:=_leaf_point(u0,v0,side); var b:=_leaf_point(u1,v0,side); var c:=_leaf_point(u1,v1,side); var d:=_leaf_point(u0,v1,side)
				if side>0: _add_tri(st,a,b,c,u0,u1,u1,side); _add_tri(st,a,c,d,u0,u1,u0,side)
				else: _add_tri(st,a,c,b,u0,u1,u1,side); _add_tri(st,a,d,c,u0,u0,u1,side)
	for edge_j in [0,seg_w]:
		for i in range(seg_l):
			var u0:=float(i)/seg_l; var u1:=float(i+1)/seg_l; var v:=float(edge_j)/seg_w
			var t0:=_leaf_point(u0,v,1); var t1:=_leaf_point(u1,v,1); var b0:=_leaf_point(u0,v,-1); var b1:=_leaf_point(u1,v,-1)
			_add_tri(st,t0,b0,b1,u0,u0,u1,0); _add_tri(st,t0,b1,t1,u0,u1,u1,0)
	st.generate_normals(); return st.commit()

func _leaf_point(u:float,v:float,side:float)->Vector3:
	var across:=(v-.5)*2.0; var point:float=profile.point
	var base_open:=pow(sin(PI*clamp(u*.94+.025,0.0,1.0)),.58)
	var tip_taper:=pow(max(0.0,1.0-pow(max(0.0,u-.68)/.32,point)),.72); var envelope:=base_open*tip_taper
	var wave:=1.0+sin(u*PI*7.0+across*2.0)*float(profile.frill)*pow(abs(across),4.0)
	var x:=across*float(profile.width)*envelope*wave
	var center:=float(profile.arch)*sin(PI*u)-.055*u+float(profile.tip_lift)*pow(u,4.2)
	var oval:=sqrt(max(0.0,1.0-across*across)); var thickness:=pow(envelope,.62)*(.72+.28*sin(PI*u))
	var y:=center+side*float(profile.thick)*oval*thickness
	y+=side*.025*pow(1.0-abs(across),2.0)*sin(PI*u)
	return Vector3(x,y,u*float(profile.length))

func _vertex_color(u:float,side:float)->Color:
	var mix:=smoothstep(.73,.98,u); var color:=base_color.darkened(.18).lightened(float(profile.powder)*.075).lerp(tip_color.darkened(.12),mix*.86)
	if side<0: color=color.darkened(.12)
	if style.begins_with("gold_"): color=color.lightened(.06*sin(u*PI))
	return color

func _add_tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,ua:float,ub:float,uc:float,side:float)->void:
	for pair in [[a,ua],[b,ub],[c,uc]]:
		st.set_color(_vertex_color(float(pair[1]),side)); st.set_uv(Vector2((pair[0].x+.8)/1.6,float(pair[1]))); st.add_vertex(pair[0])

func _build_rosette(mesh:ArrayMesh,material:StandardMaterial3D)->void:
	var rings:Array=profile.rings
	for ring_i in range(rings.size()):
		var count:int=int(rings[ring_i]); var ring_t:=float(ring_i)/float(rings.size()-1)
		for j in range(count):
			var leaf:=MeshInstance3D.new(); leaf.mesh=mesh; leaf.material_override=material
			var yaw:=TAU*float(j)/count+ring_i*float(profile.spiral)+rng.randf_range(-.028,.028); leaf.rotation.y=yaw
			var radial:float=lerp(.38+float(profile.open),.028,ring_t); leaf.position=Vector3(sin(yaw)*radial,ring_t*.075-.08,cos(yaw)*radial)
			leaf.rotation.x=lerp(-.12-float(profile.open),-float(profile.inner),ring_t)+rng.randf_range(-.025,.025)
			var base_s:float=lerp(1.0,.43,ring_t); leaf.scale=Vector3.ONE*base_s*rng.randf_range(.975,1.025)
			leaf.set_meta("ring",ring_t); leaf.set_meta("phase",rng.randf_range(0,TAU)); leaf.set_meta("base_scale",base_s)
			add_child(leaf); leaf_nodes.append(leaf)

func _build_crown_bud()->void:
	var bud:=MeshInstance3D.new(); var mesh:=SphereMesh.new(); mesh.radius=.17; mesh.height=.24; mesh.radial_segments=12; mesh.rings=6; bud.mesh=mesh
	var mat:=StandardMaterial3D.new(); mat.albedo_color=base_color.lightened(float(profile.powder)*.11); mat.roughness=float(profile.powder); bud.material_override=mat
	bud.position.y=.06; bud.scale=Vector3(1,.55,1); add_child(bud)

func _build_golden_aura()->void:
	var light:=OmniLight3D.new(); light.light_color=Color("#ffd783"); light.light_energy=.16; light.omni_range=2.5; add_child(light)
	golden_particles=GPUParticles3D.new(); golden_particles.amount=9; golden_particles.lifetime=2.8; golden_particles.randomness=.82
	var process:=ParticleProcessMaterial.new(); process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; process.emission_sphere_radius=.82
	process.initial_velocity_min=.025; process.initial_velocity_max=.075; process.gravity=Vector3(0,.055,0); process.scale_min=.018; process.scale_max=.04; golden_particles.process_material=process
	var quad:=QuadMesh.new(); quad.size=Vector2(.075,.075); var mat:=StandardMaterial3D.new(); mat.albedo_color=Color(1,.88,.48,.72); mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; quad.material=mat
	golden_particles.draw_pass_1=quad; add_child(golden_particles)

func simulate(delta:float)->void:
	if state!="growing": return
	age+=delta; var pulse:=1.0+sin(age*2.0+rng.seed%23)*.010; diameter_cm+=delta*growth_rate*(1.55+diameter_cm*.055)
	visual_scale=(.14+pow(diameter_cm/12.0,.78)*.74)*pulse
	for leaf in leaf_nodes:
		var ring_t:float=leaf.get_meta("ring"); var phase:float=leaf.get_meta("phase"); var base_s:float=leaf.get_meta("base_scale")
		var unfold:float=clamp(age/(2.6+ring_t*2.2),0.0,1.0)
		leaf.rotation.x=lerp(-1.18+ring_t*.12,-.12-ring_t*float(profile.inner),ease(unfold,.48))+sin(age*1.45+phase)*.010
		var plump:float=.82+unfold*.18+min(age/48.0,.11); leaf.scale=Vector3(plump,.86+unfold*.18,.91+unfold*.12)*base_s
	scale=Vector3.ONE*visual_scale; position+=(original_pos+target_offset-position)*min(delta*1.8,1.0)
	var danger:=get_risk_percent()
	if danger>64: wobble+=delta; rotation.z=sin(wobble*13.0)*.018*inverse_lerp(64,100,danger); danger_badge.visible=true if danger_badge else false
	if age>1.8 and rng.randf()<_jelly_probability(delta): jelly()

func _jelly_probability(delta:float)->float:
	var maturity:float=max(0.0,age-2.0); var life_pressure:=pow(maturity/max_life_hint,2.25); var size_pressure:=pow(max(0.0,diameter_cm-5.0)/28.0,1.75)
	return clamp((life_pressure*.34+size_pressure*.13)*risk_bias*delta,0.0,.34)

func get_risk_percent()->float:
	var maturity:float=max(0.0,age-1.5); return clamp((pow(maturity/max_life_hint,1.7)*72.0+pow(max(0,diameter_cm-7.0)/30.0,1.4)*32.0)*risk_bias,2.0,99.0)

func harvest()->void:
	if state!="growing":return
	state="harvested"; harvested.emit(self)

func jelly()->void:
	if state!="growing":return
	state="jelly"
	for leaf in leaf_nodes:
		var mat:=leaf.material_override.duplicate() as StandardMaterial3D; mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color=Color(.72,.78,.74,.78); mat.roughness=.22; leaf.material_override=mat
	jellied.emit(self)

func hit_radius()->float:
	return max(.24,visual_scale*(1.10 if style in ["kannte","gold_kannte"] else .96))
