extends Node

const SucculentClass = preload("res://scripts/succulent.gd")
const TARGET_COUNT := 9
const POT_RADIUS := 4.35
const UI_CREAM := Color("#fff1d2")
const UI_BROWN := Color("#4a2618")
const UI_GOLD := Color("#e8aa35")

var rng := RandomNumberGenerator.new()
var species: Array = []
var plants: Array = []
var camera: Camera3D
var world_root: Node3D
var labels_layer: Control
var effects_layer: Control
var best_label: Label
var coin_label: Label
var record_card: PanelContainer
var record_text: Label
var coins := 12450
var bests: Dictionary = {}
var spawn_queue := 0
var spawn_timer := 0.0
var forced_golden_done := false
var backdrop: Sprite3D

func _ready() -> void:
	rng.randomize()
	_load_species()
	_load_save()
	_build_world()
	_build_ui()
	for i in range(TARGET_COUNT): spawn_plant(i == 0 and OS.has_feature("editor"))
	get_viewport().size_changed.connect(_layout)
	_layout()

func _load_species() -> void:
	var raw := FileAccess.get_file_as_string("res://data/species-v2.json")
	var all_species: Array = JSON.parse_string(raw)
	var enabled := ["colorata", "lutea", "affinis", "laui", "kannte", "golden_laui"]
	for entry in all_species:
		if str(entry.species_id) in enabled:
			species.append(entry)

func _load_save() -> void:
	if FileAccess.file_exists("user://records.json"):
		var value = JSON.parse_string(FileAccess.get_file_as_string("user://records.json"))
		if value is Dictionary:
			bests = value.get("bests",{}); coins = int(value.get("coins",12450))

func _save() -> void:
	var f := FileAccess.open("user://records.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"bests":bests,"coins":coins}))

func _build_world() -> void:
	world_root = Node3D.new(); add_child(world_root)
	backdrop = Sprite3D.new()
	backdrop.texture = load("res://assets/greenhouse.png")
	# Keep the shelves and glasshouse visible above the pot, rather than
	# cropping the tall source image down to its stone-floor section.
	backdrop.position = Vector3(0.0, -5.0, -8.0)
	backdrop.pixel_size = 0.0085
	backdrop.shaded = false
	backdrop.modulate = Color(0.92,0.92,0.84)
	world_root.add_child(backdrop)
	# circular terracotta bowl: thick outer wall + inset soil
	var pot := MeshInstance3D.new(); var pot_mesh := CylinderMesh.new()
	pot_mesh.top_radius = 5.18; pot_mesh.bottom_radius = 4.55; pot_mesh.height = 1.25; pot_mesh.radial_segments = 64
	pot.mesh = pot_mesh; pot.position.y = -0.68
	pot.material_override = _terracotta_material(false)
	world_root.add_child(pot)
	var rim := MeshInstance3D.new(); var torus := TorusMesh.new()
	torus.inner_radius = 4.72; torus.outer_radius = 5.28; torus.rings = 64; torus.ring_segments = 12
	rim.mesh = torus; rim.position.y = 0.01; rim.material_override = _terracotta_material(true); world_root.add_child(rim)
	var soil := MeshInstance3D.new(); var soil_mesh := CylinderMesh.new()
	soil_mesh.top_radius=4.74; soil_mesh.bottom_radius=4.7; soil_mesh.height=0.18; soil_mesh.radial_segments=64
	soil.mesh=soil_mesh; soil.position.y=-0.08; soil.material_override=_soil_material(); world_root.add_child(soil)
	# Dense, mixed akadama/pumice grit: small real geometry catches the warm
	# greenhouse light and avoids the flat black-brown board-game look.
	var pebble_mesh := SphereMesh.new(); pebble_mesh.radius=0.072; pebble_mesh.height=0.092; pebble_mesh.radial_segments=8; pebble_mesh.rings=5
	var multi := MultiMesh.new(); multi.transform_format=MultiMesh.TRANSFORM_3D; multi.use_colors=true; multi.instance_count=560; multi.mesh=pebble_mesh
	for i in range(multi.instance_count):
		var a:=rng.randf_range(0,TAU); var r:=sqrt(rng.randf())*4.55
		var t:=Transform3D(Basis().rotated(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(rng.randf_range(.55,1.75),rng.randf_range(.38,1.0),rng.randf_range(.55,1.55))),Vector3(cos(a)*r,0.045,sin(a)*r))
		var grit_colors := [Color("#9a4e2f"),Color("#bb7450"),Color("#7a3b27"),Color("#d0aa78"),Color("#8d765c"),Color("#d8c8a3")]
		multi.set_instance_transform(i,t); multi.set_instance_color(i,grit_colors[rng.randi_range(0,grit_colors.size()-1)] * rng.randf_range(.82,1.08))
	var pebble_mat:=_mat(Color("#b48661"),0.90,0.0);pebble_mat.vertex_color_use_as_albedo=true
	var pebbles:=MultiMeshInstance3D.new(); pebbles.multimesh=multi; pebbles.material_override=pebble_mat; world_root.add_child(pebbles)
	var env_node:=WorldEnvironment.new(); var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR; env.background_color=Color("#cfd6ad"); env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("#b9ac98"); env.ambient_light_energy=0.18
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env_node.environment=env; world_root.add_child(env_node)
	var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-48,-32,-12); sun.light_color=Color("#ffe3aa"); sun.light_energy=0.40; sun.shadow_enabled=true; sun.directional_shadow_max_distance=24; sun.shadow_blur=2.5; world_root.add_child(sun)
	var fill:=OmniLight3D.new(); fill.position=Vector3(-3,5,3); fill.light_color=Color("#cbe5cc"); fill.light_energy=0.10; fill.omni_range=10; fill.shadow_enabled=false; world_root.add_child(fill)
	camera=Camera3D.new(); camera.position=Vector3(0,10.4,9.2); camera.look_at_from_position(camera.position,Vector3(0,0,-0.25)); camera.fov=39.0; camera.current=true; world_root.add_child(camera)
	world_root.position=Vector3(0,-0.35,0.35)

func _mat(color: Color, rough: float, metallic: float) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=color; m.roughness=rough; m.metallic=metallic; return m

func _terracotta_material(is_rim: bool) -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
render_mode specular_schlick_ggx;
uniform vec3 clay_dark : source_color = vec3(0.31,0.105,0.055);
uniform vec3 clay_light : source_color = vec3(0.58,0.245,0.12);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){float grain=hash(floor(UV*vec2(180.0,90.0)));float bands=sin(UV.y*55.0+sin(UV.x*19.0))*0.5+0.5;float wear=smoothstep(0.40,0.92,grain)*0.13;ALBEDO=mix(clay_dark,clay_light,0.46+bands*0.12+wear);ROUGHNESS=0.78;SPECULAR=0.25;}"""
	var material:=ShaderMaterial.new();material.shader=shader
	if is_rim: material.set_shader_parameter("clay_light",Color("#a94f2c"));material.set_shader_parameter("clay_dark",Color("#572315"))
	return material

func _soil_material()->ShaderMaterial:
	var shader:=Shader.new();shader.code="""shader_type spatial;
void fragment(){float a=sin(UV.x*173.0+sin(UV.y*61.0)*2.7)*sin(UV.y*157.0+sin(UV.x*47.0)*2.2);float b=sin(UV.x*43.0+UV.y*51.0)*.5+.5;float grain=clamp(a*.5+.5,0.0,1.0);vec3 lo=vec3(.105,.047,.027);vec3 hi=vec3(.31,.145,.075);vec3 c=mix(lo,hi,grain*.34+b*.12);ALBEDO=c;ROUGHNESS=.96;SPECULAR=.08;}""";var material:=ShaderMaterial.new();material.shader=shader;return material

func _build_ui() -> void:
	var ui:=CanvasLayer.new(); ui.layer=10; add_child(ui)
	labels_layer=Control.new(); labels_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); labels_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(labels_layer)
	var hud:=Control.new(); hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hud.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(hud)
	effects_layer=Control.new(); effects_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); effects_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(effects_layer)
	var game_theme:=Theme.new();game_theme.default_font=load("res://assets/fonts/ZenMaruGothic-Bold.ttf") as Font;game_theme.default_font_size=16
	labels_layer.theme=game_theme;hud.theme=game_theme;effects_layer.theme=game_theme
	# logo
	var logo:=Label.new(); logo.text="ぷくぷく\n多 肉"; logo.position=Vector2(26,34); logo.size=Vector2(190,105); logo.add_theme_font_size_override("font_size",31); logo.add_theme_color_override("font_color",Color("#fff2d3")); logo.add_theme_color_override("font_outline_color",UI_BROWN); logo.add_theme_constant_override("outline_size",8); logo.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hud.add_child(logo)
	var ribbon:=Label.new(); ribbon.text=" PUKU PUKU TANIKU "; ribbon.position=Vector2(56,126); ribbon.add_theme_font_size_override("font_size",11); ribbon.add_theme_color_override("font_color",Color.WHITE); ribbon.add_theme_stylebox_override("normal",_box(Color("#d99a3c"),Color("#7b4a25"),12,2)); hud.add_child(ribbon)
	var best_panel:=PanelContainer.new(); best_panel.position=Vector2(220,54); best_panel.size=Vector2(168,66); best_panel.add_theme_stylebox_override("panel",_box(Color("#47261b"),Color("#f5c985"),16,2)); hud.add_child(best_panel)
	best_label=Label.new(); best_label.text="最高  ベスト記録\n     0.0 cm"; best_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; best_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; best_label.add_theme_font_size_override("font_size",17); best_label.add_theme_color_override("font_color",Color.WHITE); best_panel.add_child(best_label)
	var coin_panel:=PanelContainer.new(); coin_panel.position=Vector2(398,54); coin_panel.size=Vector2(153,53); coin_panel.add_theme_stylebox_override("panel",_box(Color("#55301d"),Color("#f1d19c"),22,2)); hud.add_child(coin_panel)
	coin_label=Label.new(); coin_label.text=" ●  %s  ＋" % _comma(coins); coin_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; coin_label.add_theme_font_size_override("font_size",20); coin_label.add_theme_color_override("font_color",Color("#ffd85b")); coin_panel.add_child(coin_label)
	for entry in [{"x":421,"t":"図鑑"},{"x":495,"t":"設定"}]:
		var b:=Button.new(); b.text=entry.t; b.position=Vector2(entry.x,116); b.size=Vector2(68,73); _skin_button(b,Color("#fff0cf"),17); hud.add_child(b)
	# lower gradient cards
	var harvest:=Button.new(); harvest.text="タップで 収穫！"; harvest.position=Vector2(24,829); harvest.size=Vector2(360,121); _skin_button(harvest,Color("#caa538"),27); harvest.mouse_filter=Control.MOUSE_FILTER_IGNORE; hud.add_child(harvest)
	record_card=PanelContainer.new(); record_card.position=Vector2(394,816); record_card.size=Vector2(164,134); record_card.add_theme_stylebox_override("panel",_box(Color("#674135"),Color("#f4d36e"),18,3)); record_card.visible=false; hud.add_child(record_card)
	record_text=Label.new(); record_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; record_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; record_text.add_theme_font_size_override("font_size",19); record_text.add_theme_color_override("font_color",Color.WHITE); record_card.add_child(record_text)
	var nav:=HBoxContainer.new(); nav.position=Vector2(23,957); nav.size=Vector2(530,80); nav.add_theme_constant_override("separation",4); hud.add_child(nav)
	for item in ["図鑑","ホーム","マーケット"]:
		var b:=Button.new(); b.text=item; b.custom_minimum_size=Vector2(174,76); _skin_button(b,Color("#6d472d") if item!="ホーム" else Color("#fff0cf"),18); nav.add_child(b)
	_update_best_ui()

func _box(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border
	s.set_border_width_all(width); s.set_corner_radius_all(radius); s.shadow_color=Color(0.18,0.08,0.02,0.34); s.shadow_size=6; s.shadow_offset=Vector2(0,3); s.content_margin_left=10; s.content_margin_right=10; s.content_margin_top=6; s.content_margin_bottom=6; return s

func _skin_button(b:Button,bg:Color,font_size:int)->void:
	b.add_theme_font_size_override("font_size",font_size); b.add_theme_color_override("font_color",UI_BROWN if bg.get_luminance()>.55 else Color.WHITE); b.add_theme_color_override("font_hover_color",UI_BROWN); b.add_theme_stylebox_override("normal",_box(bg,bg.lightened(.22),20,3)); b.add_theme_stylebox_override("hover",_box(bg.lightened(.08),Color.WHITE,20,3)); b.add_theme_stylebox_override("pressed",_box(bg.darkened(.08),bg.lightened(.2),20,3))

func _layout() -> void:
	var size:=get_viewport().get_visible_rect().size
	if backdrop:
		backdrop.pixel_size = 0.0085

func spawn_plant(force_golden := false) -> void:
	var chosen:Dictionary
	if force_golden:
		for entry in species:
			if str(entry.visual_variant) == "gold_laui": chosen = entry
		if chosen.is_empty(): chosen = species[0]
		forced_golden_done=true
	else: chosen=_weighted_species()
	var pos:=_find_spawn_position()
	var label:=_plant_label(); labels_layer.add_child(label)
	var p = SucculentClass.new()
	p.original_pos=pos; p.position=pos; world_root.add_child(p); p.setup(chosen,rng.randi(),label,null)
	p.harvested.connect(_on_harvested); p.jellied.connect(_on_jellied)
	plants.append(p)

func _weighted_species()->Dictionary:
	var total:=0.0
	for s in species: total+=float(s.spawn_weight)
	var roll:=rng.randf()*total
	for s in species:
		roll-=float(s.spawn_weight)
		if roll<=0:return s
	return species[0]

func _find_spawn_position()->Vector3:
	if plants.is_empty(): return Vector3(0,0.08,0)
	var best:=Vector3.ZERO; var best_dist:=-1.0
	for attempt in range(32):
		var a:=rng.randf_range(0,TAU); var r:=sqrt(rng.randf())*3.48; var p:=Vector3(cos(a)*r,0.08,sin(a)*r)
		var nearest:=99.0
		for q in plants: if is_instance_valid(q): nearest=min(nearest,Vector2(p.x,p.z).distance_to(Vector2(q.position.x,q.position.z)))
		if nearest>best_dist:best=p;best_dist=nearest
		if nearest>1.15:return p
	return best

func _plant_label()->Label:
	var l:=Label.new(); l.text="1.6 cm"; l.size=Vector2(92,34); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; l.add_theme_font_size_override("font_size",17); l.add_theme_color_override("font_color",Color.WHITE); l.add_theme_stylebox_override("normal",_box(Color(0.14,0.08,0.05,.92),Color("#f4e1be"),11,2)); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; return l

func _process(delta:float)->void:
	for p in plants:
		if is_instance_valid(p): p.simulate(delta)
	_resolve_crowding(delta)
	_update_labels()
	if spawn_queue>0:
		spawn_timer-=delta
		if spawn_timer<=0: spawn_queue-=1; spawn_plant(); spawn_timer=rng.randf_range(.35,.9)

func _resolve_crowding(_delta:float)->void:
	# Sprite plants remain rooted at their spawn point. Natural overlap is less
	# distracting than sliding a planted rosette around as it grows.
	for p in plants:
		if is_instance_valid(p):
			p.target_offset = Vector3.ZERO
			p.position.x = p.original_pos.x
			p.position.z = p.original_pos.z

func _update_labels()->void:
	var occupied:Array[Rect2]=[]
	var sorted:=plants.duplicate(); sorted.sort_custom(func(a,b):return a.position.z<b.position.z)
	for p in sorted:
		if not is_instance_valid(p):continue
		var screen:=camera.unproject_position(p.global_position+Vector3(0,p.visual_scale*.7,0))
		var r:=Rect2(screen-Vector2(46,62),Vector2(92,34))
		for other in occupied:
			if r.intersects(other):r.position.y=other.position.y-37
		occupied.append(r)
		p.label.position=r.position; p.label.text="%.1f cm"%p.diameter_cm; p.label.visible=p.state=="growing"

func _unhandled_input(event:InputEvent)->void:
	var pressed: bool = event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT
	pressed=pressed or (event is InputEventScreenTouch and event.pressed)
	if not pressed:return
	var screen_pos:Vector2=event.position
	# label-aware screen selection favors small visible plants when overlap occurs
	var candidates:Array=[]
	for p in plants:
		if not is_instance_valid(p) or p.state!="growing":continue
		var center: Vector2 = camera.unproject_position(p.global_position+Vector3(0,p.visual_scale*.25,0));var radius: float=clamp(28.0+p.visual_scale*58.0,32.0,145.0)
		var dist: float=center.distance_to(screen_pos)
		if dist<radius:candidates.append({"p":p,"score":dist/max(radius,1.0)+p.visual_scale*.08})
	if candidates.size()>0:
		candidates.sort_custom(func(a,b):return a.score<b.score);candidates[0].p.harvest()

func _on_harvested(p)->void:
	var old:=float(bests.get(p.data.species_id,0.0));var is_record:bool=p.diameter_cm>old
	if is_record:bests[p.data.species_id]=p.diameter_cm
	var reward:=int(p.diameter_cm*11.0)*(4 if str(p.data.rarity)=="スーパーレア" else 1);coins+=reward;_save();_update_best_ui();coin_label.text=" ●  %s  ＋"%_comma(coins)
	_show_float(p,"GET!\n%s  %.1fcm"%[p.data.name_ja,p.diameter_cm],Color("#fff3a2"))
	if is_record:_show_record(p,reward)
	var tween:=create_tween().set_parallel();tween.tween_property(p,"position:y",p.position.y+2.0,.42).set_trans(Tween.TRANS_BACK);tween.tween_property(p,"scale",p.scale*1.2,.22);tween.chain().tween_property(p,"scale",Vector3.ONE*0.01,.24)
	_cleanup_later(p,.68)

func _on_jellied(p)->void:
	_show_float(p,"ぷるん…\nジュレ",Color("#e7c9f0"))
	var tw:=create_tween();tw.tween_property(p,"scale",Vector3(p.scale.x*1.05,p.scale.y*.46,p.scale.z*1.05),.28).set_trans(Tween.TRANS_BOUNCE);tw.tween_interval(.25);tw.tween_property(p,"scale",Vector3.ONE*0.01,.38)
	_cleanup_later(p,1.0)

func _cleanup_later(p,delay:float)->void:
	plants.erase(p);spawn_queue+=1;spawn_timer=rng.randf_range(.35,.85)
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(p):p.label.queue_free();p.queue_free()

func _show_float(p,text:String,color:Color)->void:
	var l:=Label.new();l.text=text;l.size=Vector2(230,90);l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.add_theme_font_size_override("font_size",24);l.add_theme_color_override("font_color",color);l.add_theme_color_override("font_outline_color",UI_BROWN);l.add_theme_constant_override("outline_size",7);l.position=camera.unproject_position(p.global_position)-Vector2(115,40);effects_layer.add_child(l)
	var tw:=create_tween().set_parallel();tw.tween_property(l,"position:y",l.position.y-85,.62).set_trans(Tween.TRANS_BACK);tw.tween_property(l,"modulate:a",0.0,.62).set_delay(.18);tw.chain().tween_callback(l.queue_free)

func _show_record(p,reward:int)->void:
	record_text.text="収穫記録更新！\nNEW RECORD\n%.1f cm\nコイン +%d"%[p.diameter_cm,reward];record_card.visible=true;record_card.scale=Vector2(.72,.72);record_card.pivot_offset=record_card.size/2
	var tw:=create_tween();tw.tween_property(record_card,"scale",Vector2.ONE,.24).set_trans(Tween.TRANS_BACK);tw.tween_interval(2.2);tw.tween_property(record_card,"modulate:a",0.0,.25);tw.tween_callback(func():record_card.visible=false;record_card.modulate.a=1.0)

func _update_best_ui()->void:
	var top:=0.0
	for v in bests.values():top=max(top,float(v))
	best_label.text="最高  ベスト記録\n     %.1f cm"%top

func _comma(value:int)->String:
	var s:=str(value);var out:="";var count:=0
	for i in range(s.length()-1,-1,-1):
		if count>0 and count%3==0:out=","+out
		out=s[i]+out;count+=1
	return out
