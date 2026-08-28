extends Node3D
const SucculentClass=preload("res://scripts/succulent.gd")
var specimen:Succulent
func _ready()->void:
	var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("#d9cfb7");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("#b9ad98");env.ambient_light_energy=.20;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment=env;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-28,-10);sun.light_color=Color("#ffe2b0");sun.light_energy=.38;sun.shadow_enabled=true;add_child(sun)
	var ground:=MeshInstance3D.new();var gm:=CylinderMesh.new();gm.top_radius=2.2;gm.bottom_radius=2.2;gm.height=.18;ground.mesh=gm;ground.position.y=-.15;var soil:=StandardMaterial3D.new();soil.albedo_color=Color("#4a2b20");soil.roughness=.98;ground.material_override=soil;add_child(ground)
	specimen=SucculentClass.new();specimen.name="Specimen";add_child(specimen);var sample={"species_id":"laui","name_ja":"ラウイ","rarity":"レア","spawn_weight":1.0,"base_growth_rate":1.0,"jelly_risk_curve":0.0,"visual_variant":"laui","golden_variant":true,"colors":["8fa6b0","9fb2b9"]};specimen.setup(sample,8813,null,null);specimen.age=7.0;specimen.diameter_cm=16.0;specimen.max_life_hint=100000.0
	var camera:=Camera3D.new();camera.position=Vector3(0,5.6,7.0);camera.look_at_from_position(camera.position,Vector3(0,.25,0));camera.fov=34;camera.current=true;add_child(camera)
func _process(delta:float)->void:
	specimen.simulate(delta*.12)
