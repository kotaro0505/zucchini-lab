extends Node3D
const SucculentClass=preload("res://scripts/succulent.gd")
func _ready()->void:
	var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("#cfc4aa");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("#b8aa92");env.ambient_light_energy=.20;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment=env;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-32,-12);sun.light_color=Color("#ffe3aa");sun.light_energy=.40;sun.shadow_enabled=true;add_child(sun)
	var data:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/species-v2.json"))
	for i in range(data.size()):
		var plant:=SucculentClass.new() as Succulent;plant.name=str(data[i].species_id);var col:=i%3;var row:=i/3;plant.position=Vector3((col-1)*2.35,0,(row-1.5)*2.2);plant.original_pos=plant.position;add_child(plant);plant.setup(data[i],1200+i,null,null);plant.age=7;plant.diameter_cm=11.5;plant.max_life_hint=100000
	var ground:=MeshInstance3D.new();var gm:=PlaneMesh.new();gm.size=Vector2(8,11);ground.mesh=gm;var mat:=StandardMaterial3D.new();mat.albedo_color=Color("#422519");mat.roughness=.95;ground.material_override=mat;ground.position.y=-.2;add_child(ground)
	var camera:=Camera3D.new();camera.position=Vector3(0,12.5,11.8);camera.look_at_from_position(camera.position,Vector3(0,0,1.0));camera.fov=36;camera.current=true;add_child(camera)
func _process(delta:float)->void:
	for child in get_children():
		if child is Succulent:child.simulate(delta*.035)
